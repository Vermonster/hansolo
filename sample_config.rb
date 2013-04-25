Hansolo.configure do |config|
  config.local_tmp_dir = '/tmp'

  config.before_rsync_cookbooks = Proc.new do |hansolo|
    Hansolo::Util.call("rm -rf #{hansolo.local_tmp_dir} && bundle exec berks install --path #{hansolo.local_tmp_dir}")
  end

  config.before_rsync_databags = Proc.new do |hansolo|
    # Grab JSON file from S3, and place it into a conventional place
    Hansolo::Util.call("mkdir -p #{File.join(local_data_bags_tmpdir, 'app')}")

    aws_data_bag_keys.each do |key_name|
      item = s3_bucket.objects[key_name]
      base_key_name = File.basename(key_name)
      File.open(File.join(local_data_bags_tmpdir, 'app', base_key_name), 'w') do |f|
        f.write item.read
      end if item.exists?
    end
  end
end
