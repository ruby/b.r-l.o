namespace :redmica_s3 do
  desc 'Upload the attachment files to AWS S3.'
  task files_to_s3: :environment do
    require 'thread'

    def s3_file_data(file_path)
      target     = file_path
      filename   = File.basename(file_path)
      digest     = nil
      if attachment = Attachment.find_by_disk_filename(filename)
        target   = attachment.diskfile
        filename = attachment.filename unless attachment.filename.blank?
        digest   = attachment.digest.presence
      else
        target   = Pathname.new(file_path).relative_path_from(Pathname.new(Attachment.storage_path)).to_s
      end
      {source: file_path, target: target, filename: filename, digest: digest}
    end

    # updates a single file on s3
    def update_file_on_s3(data)
      source   = data[:source]
      target   = data[:target]
      return if target.nil?
      object = RedmicaS3::Connection.object(target)
      # get the file modified time, which will stay nil if the file doesn't exist yet
      # we could check if the file exists, but this saves a head request
      s3_mtime = object.last_modified rescue nil

      # put it on s3 if the file has been updated or it doesn't exist on s3 yet
      if s3_mtime.nil? || File.mtime(source) > s3_mtime
        filename = data[:filename]
        digest = data[:digest].presence
        File.open(source, 'rb') do |file_obj|
          if file_obj.size > Setting.attachment_max_size.to_i.kilobytes
            puts "File #{target} cannot be uploaded because it exceeds the maximum allowed file size (#{Setting.attachment_max_size.to_i.kilobytes})"
            return
          end
          content_type = IO.popen(["file", "--brief", "--mime-type", file_obj.path], in: :close, err: :close) { |io| io.read.chomp } rescue nil
          content_type ||= 'application/octet-stream'
          RedmicaS3::Connection.put(target, filename, file_obj.read, content_type, {digest: digest})
        end

        puts "Put file #{target}"
      else
        puts File.basename(source) + ' is up-to-date on S3'
      end
    end

    # enqueue all of the files to be "worked" on
    file_q = Queue.new
    Dir.glob(File.join(Attachment.storage_path, '**/*')).each do |file|
      file_q << s3_file_data(file) if File.file? file
    end

    # create some threads to start syncing all of the queued files with s3
    threads = Array.new
    8.times do
      threads << Thread.new do
        while !file_q.empty?
          update_file_on_s3(file_q.pop)
        end
      end
    end

    # wait on all of the threads to finish
    threads.each do |thread|
      thread.join
    end

  end
end
