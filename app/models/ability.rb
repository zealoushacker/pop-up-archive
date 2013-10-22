class Ability
  include CanCan::Ability

  def initialize(user)

    if user && user.has_role?(:super_admin)
      can :manage, :all
    else

      can :read,   Collection
      can :create, Collection
      can :manage, Collection, id: (user ? user.collection_ids : [])

      can :read,   Item
      can :manage, Item, collection: { id: (user ? user.collection_ids : []) }

      can :read,   Entity
      can :manage, Entity, item: { collection: { id: (user ? user.collection_ids : []) }}

      can :read,   Contribution
      can :manage, Contribution, item: { collection: { id: (user ? user.collection_ids : []) }}

      can :read, Admin::TaskList if (user && user.has_role?("super_admin"))

      # can :order_transcript, AudioFile if (user && (user.organization_id.nil? || (!user.organization_id.nil? && user.has_role?("admin", user.organization))))
      can :manage, AudioFile, item: { collection: { id: (user ? user.collection_ids : []) }}
      can :order_transcript, AudioFile if (user && !user.organization_id.nil? && user.has_role?("admin", user.organization))
      can :add_to_amara,     AudioFile if (user && !user.organization_id.nil? && user.has_role?("admin", user.organization))

      can :read,   Organization
      can :manage, Organization, id: (user ? user.organization_id : nil)
    end

  end
end
