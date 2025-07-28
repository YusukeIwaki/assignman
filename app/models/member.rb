# == Schema Information
#
# Table name: members
#
#  id                     :integer          not null, primary key
#  name                   :string           not null
#  standard_working_hours :decimal(5, 1)    default(40.0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Member < ApplicationRecord
  has_many :rough_project_assignments, dependent: :destroy
  has_many :detailed_project_assignments, dependent: :destroy
  has_many :ongoing_assignments, dependent: :destroy
  has_many :standard_projects, through: :detailed_project_assignments
  has_many :ongoing_projects, through: :ongoing_assignments
  has_many :member_skills, dependent: :destroy
  has_many :skills, through: :member_skills

  validates :name, presence: true
  validates :standard_working_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 80 }

  def scheduled_hours_on_date(date = Date.current)
    return 0 if date.saturday? || date.sunday?

    # Calculate daily hours from detailed assignments
    detailed_assignments_on_date = detailed_project_assignments
                                   .where('start_date <= ? AND end_date >= ?', date, date)

    detailed_hours = detailed_assignments_on_date.sum do |assignment|
      assignment.scheduled_hours / assignment.working_days_count.to_f
    end

    # Calculate daily hours from ongoing assignments (weekly hours / 5)
    ongoing_hours = ongoing_assignments
                    .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                    .sum('weekly_scheduled_hours / 5.0')

    detailed_hours + ongoing_hours
  end

  def scheduled_hours_for_week(week_start_date)
    week_end_date = week_start_date + 6.days
    total_hours = 0

    (week_start_date..week_end_date).each do |date|
      next if date.saturday? || date.sunday?

      total_hours += scheduled_hours_on_date(date)
    end

    total_hours
  end

  def available_hours_on_date(date = Date.current)
    return 0 if date.saturday? || date.sunday?

    daily_working_hours = standard_working_hours / 5.0
    daily_working_hours - scheduled_hours_on_date(date)
  end

  def available_hours_for_week(week_start_date)
    week_end_date = week_start_date + 6.days
    total_available = 0

    (week_start_date..week_end_date).each do |date|
      next if date.saturday? || date.sunday?

      total_available += available_hours_on_date(date)
    end

    total_available
  end

  def total_scheduled_hours(start_date, end_date)
    detailed_hours = detailed_project_assignments
                     .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                     .sum(:scheduled_hours)

    rough_hours = rough_project_assignments
                  .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                  .sum(:scheduled_hours)

    ongoing_weeks = ((end_date - start_date).to_i / 7.0).ceil
    ongoing_hours = ongoing_assignments
                    .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', end_date, start_date)
                    .sum(:weekly_scheduled_hours) * ongoing_weeks

    detailed_hours + rough_hours + ongoing_hours
  end
end
