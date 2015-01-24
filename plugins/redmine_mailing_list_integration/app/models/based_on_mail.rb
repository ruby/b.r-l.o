module BasedOnMail
  def originates_from_mail?
    if @originates_from_mail.nil?
      @originates_from_mail = true
    else
      @originates_from_mail
    end
  end
  attr_writer :originates_from_mail
end
