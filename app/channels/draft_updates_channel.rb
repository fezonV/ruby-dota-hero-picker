class DraftUpdatesChannel < Turbo::StreamsChannel
  def subscribed
    draft = current_user&.drafts&.find_by(id: params[:draft_id])
    if draft && verified_stream_name_from_params == draft.to_gid_param
      stream_for draft
    else
      reject
    end
  end
end
