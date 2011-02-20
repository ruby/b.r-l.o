class MailingListsController < ApplicationController
  layout 'admin'
  before_filter :require_admin

  helper :sort
  include SortHelper

  def index
    list
  end

  def list
    sort_init 'identifier', 'asc'
    sort_update %w(identifier address)

    @mailing_lists = MailingList.find(:all, :order => sort_clause)
    @mailing_list_count = MailingList.count
    @mailing_list_pages = Paginator.new self, @mailing_list_count, per_page_option, params['page']

    respond_to do |format|
      format.html { 
        if request.xhr?
          render :layout => false, :action => 'list'
        else
          render :action => 'list' 
        end
      }
      format.xml  { render :xml => @mailing_lists }
    end
  end

  def new
    @mailing_list = MailingList.new
    respond_to do |format|
      format.html # add.html.erb
      format.xml  { render :xml => @mailing_list }
    end
  end

  def create
    @mailing_list = MailingList.new(params[:mailing_list])
    respond_to do |format|
      if @mailing_list.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(:action => 'index') }
        format.xml  { render :xml => @mailing_list, :status => :created, :location => @mailing_list }
      else
        format.html # add.html.erb
        format.xml  { render :xml => @mailing_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @mailing_list = MailingList.find(params[:id])
    @projects = Project.find(:all, :order => 'name', :conditions => "status=#{Project::STATUS_ACTIVE}") - @mailing_list.projects
    @use = UseOfMailingList.new
  end

  def update
    edit
    respond_to do |format|
      if @mailing_list.update_attributes(params[:mailing_list])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(:action => 'edit', :id => @mailing_list) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mailing_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @mailing_list = MailingList.find(params[:id])
    @mailing_list.destroy

    respond_to do |format|
      format.html { redirect_to(:action => 'index') }
      format.xml  { head :ok }
    end
  end
end
