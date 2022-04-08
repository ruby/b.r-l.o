class UsesOfMailingListController < ApplicationController
  before_action :require_admin

  def new
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @use = @mailing_list.uses_of_mailing_list.build
  end

  def create
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @use = @mailing_list.uses_of_mailing_list.build(use_of_mailing_lists_params)
    if @use.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to controller: 'mailing_lists', action: 'edit', id: @mailing_list, tab: 'use' }
        format.any  { head :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to controller: 'mailing_lists', action: 'edit', id: @mailing_list, tab: 'use' }
        format.xml  { render xml: @use.errors, status: :unprocessable_entity }
        format.json  { render json: @use.errors, status: :unprocessable_entity }
        format.any  { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @use = @mailing_list.uses_of_mailing_list.find(params[:id])
  end

  def update
    @mailing_list = MailingList.find(params[:mailing_list_id])
    @use = @mailing_list.uses_of_mailing_list.find(params[:id])
    if @use.update_attributes(use_of_mailing_lists_params)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to controller: 'mailing_lists', action: 'edit', id: @mailing_list, tab: 'use' }
        format.any  { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to controller: 'mailing_lists', action: 'edit', id: @mailing_list, tab: 'use' }
        format.xml  { render xml: @use.errors, status: :unprocessable_entity }
        format.json  { render json: @use.errors, status: :unprocessable_entity }
        format.any  { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mailing_list = MailingList.find(params[:mailing_list_id])
    if @mailing_list.uses_of_mailing_list.destroy(params[:id])
      flash[:notice] = l(:notice_successful_delete)
    end
    respond_to do |format|
      format.html { redirect_to controller: 'mailing_lists', action: 'edit', id: @mailing_list, tab: 'use' }
      format.any { head :ok }
    end
  end

  private

  def use_of_mailing_lists_params
    params.require(:use_of_mailing_lists).permit(:receptor_name)
  end
end
