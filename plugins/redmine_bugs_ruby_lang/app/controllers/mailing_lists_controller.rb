class MailingListsController < ApplicationController
  layout 'admin'
  before_action :require_admin

  helper :sort
  include SortHelper

  def index
    list
  end

  def list
    sort_init 'identifier', 'asc'
    sort_update %w(identifier address)

    @mailing_lists = MailingList.all.order(sort_clause)
    @mailing_list_count = MailingList.count
    @mailing_list_pages = Paginator.new self, @mailing_list_count, per_page_option, params['page']

    respond_to do |format|
      format.html {
        if request.xhr?
          render layout: false, action: 'list'
        else
          render action: 'list'
        end
      }
      format.xml  { render xml: @mailing_lists }
    end
  end

  def new
    @mailing_list = MailingList.new
    respond_to do |format|
      format.html # add.html.erb
      format.xml  { render xml: @mailing_list }
    end
  end

  def create
    @mailing_list = MailingList.new(mailing_list_params)
    respond_to do |format|
      if @mailing_list.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(action: 'index') }
        format.xml  { render xml: @mailing_list, status: :created, location: @mailing_list }
      else
        format.html # add.html.erb
        format.xml  { render xml: @mailing_list.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @mailing_list = MailingList.find(params[:id])
    @projects = Project.where("status=#{Project::STATUS_ACTIVE}").order('name DESC').to_a - @mailing_list.projects
    @use = UseOfMailingList.new
  end

  def update
    edit
    respond_to do |format|
      if @mailing_list.update_attributes(mailing_list_params)
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(action: 'edit', id: @mailing_list) }
        format.xml  { head :ok }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @mailing_list.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mailing_list = MailingList.find(params[:id])
    @mailing_list.destroy

    respond_to do |format|
      format.html { redirect_to(action: 'index') }
      format.xml  { head :ok }
    end
  end

  private

  def mailing_list_params
    params.require(:mailing_list).permit(:identifier, :address, :driver_name, :driver_data, :description)
  end

end
