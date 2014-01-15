module BasedOnMail
  def originates_from_mail?
    !!@originates_from_mail
  end
  attr_writer :originates_from_mail
end
