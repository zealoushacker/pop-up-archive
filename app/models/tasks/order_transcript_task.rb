class Tasks::OrderTranscriptTask < Tasks::AddToAmaraTask

  def order_transcript
    raise "No user specified" unless user
    raise "No card on file for user.customer specified" unless user.card

    super

    raise 'no video created, cannot continue ' unless video_id

    # create task for mobile worker with this video url (and language specified?)
    # first we probably need a gem for that...

    # lastly, if all else has worked, create the charge
    charge_for_transcription
  end

  def charge_for_transcription
    invoice_item = {
      amount:      to_cents(extras['amount']),
      currency:    'usd',
      description: "#{self.id}: transcript for #{audio_file.filename}"
    }

    invoice_item = user.customer.add_invoice_item(invoice_item)
    extras['invoice_item_id'] = invoice_item.id
    save!
    invoice_item
  end

  def to_cents(dollars)
    dollars.to_i * 100
  end

  def team
    super || ENV['AMARA_TEAM_MOBILEWORKS']  # this should be an env constant perhaps?
  end

end
