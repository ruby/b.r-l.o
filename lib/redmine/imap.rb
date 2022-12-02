# frozen_string_literal: false

# Redmine - project management software
# Copyright (C) 2006-2022  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'net/imap'
require "aws-sdk-s3"
require "mail"

module Redmine
  module IMAP
    class << self
      def check(imap_options={}, options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        starttls = !imap_options[:starttls].nil?
        folder = imap_options[:folder] || 'INBOX'

        imap = Net::IMAP.new(host, port, ssl)
        if starttls
          imap.starttls
        end
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.select(folder)
        imap.uid_search(['NOT', 'SEEN']).each do |uid|
          msg = imap.uid_fetch(uid,'RFC822')[0].attr['RFC822']
          logger.debug "Receiving message #{uid}" if logger && logger.debug?
          if MailHandler.safe_receive(msg, options)

            record_s3(msg)

            logger.debug "Message #{uid} successfully received" if logger && logger.debug?
            if imap_options[:move_on_success]
              imap.uid_copy(uid, imap_options[:move_on_success])
            end
            imap.uid_store(uid, "+FLAGS", [:Seen, :Deleted])
          else
            logger.debug "Message #{uid} can not be processed" if logger && logger.debug?
            imap.uid_store(uid, "+FLAGS", [:Seen])
            if imap_options[:move_on_failure]
              imap.uid_copy(uid, imap_options[:move_on_failure])
              imap.uid_store(uid, "+FLAGS", [:Deleted])
            end
          end
        end
        imap.expunge
        imap.logout
        imap.disconnect
      end

      private

      def record_s3(msg)
        m = Mail.new(msg)
        list_name = m.header['List-Id'].to_s.match(/\<(.*)\.ml\.ruby\-lang\.org\>/)
        list_name = list_name && list_name[1]
        post_id = m.header["Subject"].to_s.match(/\[#{ml_name}:(\d+)\].*/)
        post_id = post_id && post_id[1]

        from = begin
          m.header["from"].to_s.gsub(/@[a-zA-Z.\-]+/, "@...")
        rescue
          m.header['from']
        end
        io = StringIO.new
        io.puts "From: #{from}"
        io.puts "Date: #{m.date}"
        begin
          io.puts "Subject: #{m.subject}"
        rescue Encoding::CompatibilityError
          io.puts "Subject: "
        end
        io.puts ""
        io.puts m.body.to_s.encode("UTF-8", "ISO-2022-JP", invalid: :replace, undef: :replace)

        s3 = Aws::S3::Resource.new(
          region: 'ap-northeast-1',
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
        bucket = s3.bucket('blade.ruby-lang.org')
        bucket.object("#{list_name}/#{post_id}").put(body: io.string)
      ensure
        io.close
      end

      def logger
        ::Rails.logger
      end
    end
  end
end
