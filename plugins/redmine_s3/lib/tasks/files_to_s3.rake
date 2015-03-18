namespace :redmine_s3 do
  task :files_to_s3 => :environment do
    require 'thread'

    def s3_file_path(file_path)
      file_path.split('/').last(3).join('/')
    end

    # updates a single file on s3
    def update_file_on_s3(file, objects)
      file_path = s3_file_path(file)
      object = objects[file_path]

      # get the file modified time, which will stay nil if the file doesn't exist yet
      # we could check if the file exists, but this saves a head request
      s3_mtime = object.last_modified rescue nil 

      # put it on s3 if the file has been updated or it doesn't exist on s3 yet
      if s3_mtime.nil? || s3_mtime < File.mtime(file)
        file_obj = File.open(file, 'r')
        default_content_type = 'application/octet-stream'
        content_type = IO.popen(["file", "--brief", "--mime-type", file_obj.path], in: :close, err: :close) { |io| io.read.chomp } || default_content_type rescue default_content_type
        RedmineS3::Connection.put(file_path, file_obj.read, content_type)
        file_obj.close

        puts "Put file #{File.basename(file)}"
      else
        puts File.basename(file) + ' is up-to-date on S3'
      end
    end

    # enqueue all of the files to be "worked" on
    file_q = Queue.new
    storage_path = Redmine::Configuration['attachments_storage_path'] || File.join(Rails.root, "files")
    Dir.glob(File.join(storage_path,'**/*')).each do |file|
      file_q << file if File.file? file
    end

    # init the connection, and grab the ObjectCollection object for the bucket
    conn = RedmineS3::Connection.establish_connection
    objects = conn.buckets[RedmineS3::Connection.bucket].objects

    # create some threads to start syncing all of the queued files with s3
    threads = Array.new
    8.times do
      threads << Thread.new do
        while !file_q.empty?
          update_file_on_s3(file_q.pop, objects)
        end
      end
    end
    
    # wait on all of the threads to finish
    threads.each do |thread|
      thread.join
    end

  end
end
