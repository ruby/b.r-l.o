Attachment.class_eval do
  def text?
    !!(self.filename =~ /\.(txt|rb|log|patch|diff)$/i)
  end
end
