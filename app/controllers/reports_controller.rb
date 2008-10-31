class ReportsController < ApplicationController
  protect_from_forgery :except => :create
  before_filter :filter_from_params, :only => [ :index, :chart ]
  attr_accessor :current_user
  before_filter { |ctl| ctl.current_user = Report.find(:first) }
  
  # GET /reports
  def index
    respond_to do |format|
      format.kml do
        @per_page = params[:count] || 20
        @reports = Report.with_location.paginate :page => @page, :per_page => @per_page, :order => 'created_at DESC'
        case params[:live]
        when /1/
          render :template => "reports/reports.kml.builder"
        else
          render :template => "reports/index.kml.builder"
        end
      end
      format.json do 
        @reports = Report.paginate :page => @page, :per_page => @per_page, :order => 'created_at DESC'
        render :json => @reports.to_json, :callback => params[:callback]
      end      
      format.atom do
        @reports = Report.with_location.paginate :page => @page, :per_page => @per_page, :order => 'created_at DESC'
      end
      format.html do
        @reports = Report.find_with_filters(@filters)
      end
    end
  end
  
  # GET /reports/review
  def review
    # fetches basic review layout
    @reports = Report.assigned(current_user)
  end
  
  # POST /reports/assign
  def assign
    # assigns a set of reviews to the user
    # FIXME: causes 10 updates when one would suffice
    @reports = Report.unassigned.assign(current_user)
    respond_to do |format|
      format.js { 
        render :update do |page|
          page['reports'].replace_html :partial => 'reviews', :locals => { :reports => @reports }
          page['reports'].show
        end
      }
    end
  end
  
  # POST /reports/release
  def release
    # could we do this with named_scope extensions? kinda gnarly...
    # Report.assigned(current_user).release
    Report.update_all("reviewer_id = NULL, assigned_at = NULL", [ 'reviewer_id = ? AND reviewed_at IS NULL', current_user.id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page['reports'].fade
        end
      }
    end
  end
  
  # GET /reports/:id
  def show 
    @report = Report.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page["report_#{@report.id}"].replace_html :partial => 'report_review', :locals => { :report => @report }
        end
      }
    end
  end
    
  # GET /reports/:id/edit
  def edit
    @report = Report.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page["report_#{@report.id}"].replace_html :partial => 'edit', :locals => { :report => @report }
        end
      }
    end
  end
  
  # POST /reports/:id
  def update
    @report = Report.find(params[:id])
    if @report.update_attributes(params[:report])
      respond_to do |format|
        format.xml { head :ok }
        format.js {
          render :update do |page|
            page["report_#{@report.id}"].replace_html :partial => 'report_review', :locals => { :report => @report }
            page["report_#{@report.id}"].visual_effect :highlight
          end
        }
      end
    else
      respond_to do |format|
        format.xml  { render :xml => @report.errors, :status => :unprocessable_entity }
        format.js {
          render :update do |page|
            page["error_report_#{@report.id}"].replace(
              error_messages_for(:report, :id => "error_report_#{@report.id}", :class => 'xhr_errors', :header_message => nil, :message => nil)
            ).show
          end
        }
      end
    end
  end
  
  # POST /reports/:id/confirm
  def confirm
    @report = Report.find(params[:id])
    if @report.confirm!
      respond_to do |format|
        format.xml { head :ok }
        format.js {
          render :update do |page|
            page["report_#{@report.id}"].fade
          end
        }
      end
    else
      respond_to do |format|
        format.xml { render :xml => @report.errors, :status => :unprocessable_entity }
        format.js {
          render :update do |page|
            page["error_report_#{@report.id}"].replace(
              error_messages_for(:report, :id => "error_report_#{@report.id}", :class => 'xhr_errors', :header_message => nil, :message => nil)
            ).show
          end
        }
      end
    end
  end
  
  # POST /reports/:id/dismiss
  def dismiss
    @report = Report.find(params[:id])
    @report.dismiss!
    respond_to do |format|
      format.xml { head :ok }
      format.js {
        render :update do |page|
          page["report_#{@report.id}"].fade
        end
      }
    end
  end
  
  def map  
  end
  
  def chart 
    @reports = Report.with_wait_time.find_with_filters(@filters)     
  end
  
  # POST /reports
  # Used by iPhone app and API users
  def create
    respond_to do |format|
      format.iphone do
        result = save_iphone_report(params)
        render :text => result and return true
      end
      format.android do
        result = save_android_report(params)
        render :text => result and return true
      end
    end
  end
  
  private
  # Store an iPhone-generated report given a hash of parameters
  # Check for a valid iPhone UDID
  def save_iphone_report(info)
    raise "Invalid UDID" unless info[:reporter][:uniqueid][/^[\d\-A-F]{36,40}$/i]
    reporter = IphoneReporter.update_or_create(info[:reporter])
    polling_place = PollingPlace.match_or_create(info[:polling_place][:name], reporter.location)
    report = reporter.reports.create(info[:report].merge(:polling_place => polling_place))
    "OK"
  rescue => e
    logger.info "*** IPHONE ERROR: #{e.class}: #{e.message}\n\t#{e.backtrace.first}"
    "ERROR"
  end
  
  # Store an Android-generated report given a hash of parameters
  # Check for a valid Android IMEI
  def save_android_report(info)
    raise "Invalid IMEI" unless info[:reporter][:uniqueid][/^\d{16}/]
    reporter = AndroidReporter.update_or_create(info[:reporter])
    polling_place = PollingPlace.match_or_create(info[:polling_place][:name], reporter.location)
    report = reporter.reports.create(info[:report].merge(:polling_place => polling_place))
    "OK"
  rescue => e
    logger.info "*** ANDROID ERROR: #{e.class}: #{e.message}\n\t#{e.backtrace.first}"
    "ERROR"
  end
end
