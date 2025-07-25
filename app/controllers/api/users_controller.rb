class Api::UsersController < Api::ApplicationController
  def index
    limit = params[:limit]&.to_i || 20
    offset = params[:offset]&.to_i || 0
    
    # Validate limit parameter
    limit = 100 if limit > 100
    limit = 1 if limit < 1
    
    # Validate offset parameter
    offset = 0 if offset < 0
    
    users = User.joins(:user_profile)
                .select('users.id, user_profiles.name')
                .order('users.id')
                .limit(limit)
                .offset(offset)
    
    total_count = User.count
    
    users_data = users.map do |user|
      {
        id: user.id,
        name: user.name
      }
    end
    
    render json: {
      total: total_count,
      offset: offset,
      users: users_data
    }
  end
end