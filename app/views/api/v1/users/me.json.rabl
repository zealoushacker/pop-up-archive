object false

if current_user
  node(:id) { current_user.id }
  node(:uri) { "http://pop-up-archive.org/api/users/#{current_user.id}" }
  node(:uploads_collection_id) { current_user.uploads_collection.id }
  node(:collection_ids) { current_user.collection_ids }
  node(:role) { current_user.role }

  node(:organization) {
    {
      id: current_user.organization.id,
      name: current_user.organization.name,
      amara_team: current_user.organization.amara_team
    } if current_user.organization.present?
  }

  node(:used_metered_storage) { current_user.used_metered_storage }
  node(:total_metered_storage) { current_user.pop_up_hours * 3600 }
  node(:plan) { current_user.plan_name }
  node(:has_card) { !current_user.active_credit_card.nil? }
end
