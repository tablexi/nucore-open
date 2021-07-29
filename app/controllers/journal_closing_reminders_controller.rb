# frozen_string_literal: true

class JournalClosingRemindersController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource

  layout "two_column"
  before_action { @active_tab = "global_settings" }

  def index
    @journal_closing_reminders = JournalClosingReminder.order(ends_at: :desc)
  end

  def new
    @journal_closing_reminder.starts_at = default_next_window
  end

  def create
    if @journal_closing_reminder.save
      redirect_to journal_closing_reminders_path, notice: t("journal_closing_reminders.create.success")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @journal_closing_reminder.update_attributes(journal_closing_reminder_params)
      redirect_to journal_closing_reminders_path, notice: t("journal_closing_reminders.update.success")
    else
      render :edit
    end
  end

  def destroy
    @journal_closing_reminder.destroy
    redirect_to journal_closing_reminders_path, notice: t("journal_closing_reminders.destroy.success")
  end

  private

  def default_next_window
    [JournalClosingReminder.maximum(:starts_at), Time.current].compact.max
  end

  def journal_closing_reminder_params
    params.require(:journal_closing_reminder).permit(:message, starts_at: :date, ends_at: :date)
  end

end
