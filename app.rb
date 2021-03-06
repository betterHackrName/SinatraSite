require 'rubygems'
require 'sinatra'
require 'mongo'
require 'mongo_mapper'
require 'date'

admin_info = Array.new
File.open('admin.txt', 'r').each do |line|
	admin_info.push line.strip
end

SITE_TITLE = "Austin C. Roos"
SITE_PASSWORD = admin_info[0]

host = admin_info[1]
port = admin_info[2]
db_name = admin_info[3]
user = admin_info[4]
pw = admin_info[5]

MongoMapper.connection = Mongo::Connection.new(host, port)
MongoMapper.database = db_name
MongoMapper.database.authenticate(user, pw)

class Project
  include MongoMapper::Document
  key :order,				Integer
  key :name,				String
  key :description,	String
  key :content,			Array
  key :status,			String
  key :created_at,	Time
  key :pics,				Array
  key :files,				Array
end

class Job
	include MongoMapper::Document
	key :order,					Integer
	key :company_name,	String
	key :title,					String
	key :description,		Array
	key :start_date,		String
	key :end_date,			String
end


helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

def title_empty()
	return title.empty?
end

def split_paragraphs(text)
	items = Array.new
	text.split('\r\n').each do |paragraph|
		items.push paragraph
	end
	return items
end

def split_files(text)
	files = Array.new
	text.split('\r\n').each do |file|
		files.push file
	end
	return files
end

# get '/' do
# 	@title = 'Site In Progress'
# 	erb :in_progress, :layout => :layout_under_construction
# end

# get '/welcome' do
# 		@title = 'Welcome'
# 		erb :welcome, :layout => :layout_welcome
# end

['/', '/index', '/index.html'].each do |path|
	get path do
		@header = 'Austin C. Roos'
		@label = 'Home'
		erb :home, :layout => :layout_home
	end
end

['/about', '/about.html'].each do |path|
	get path do
		@header = 'About Me'
		@title = 'About Me'
		@label = 'About'
		erb :about
	end
end

get '/experience/?' do
	@header = 'Experience'
	@title = 'Experience'
	@label = 'Experience'
	@jobs = Job.sort(:order)
	erb :experience
end

get '/experience/:id' do
	@job = Job.find_by_id params[:id]
	@header = @job.name
	@title = @job.name
	@label = 'Experience'
	if @job
		erb :job
	else
		redirect '/'
	end
end

get '/projects/?' do
	@projects = Project.sort(:created_at.desc)
	@header = 'Projects'
	@title = 'Projects'
	@label = 'Projects'
	if @projects.empty?
		redirect '/'
	else
		erb :projects
	end
end

get '/projects/:id' do
	@project = Project.find_by_id params[:id]
	@header = @project.name
	@title = @project.name
	@label = 'Projects'
	if @project
		erb :project
	else
		redirect '/'
	end
end

get '/projects/:id/pics/:pic' do
	@project = Project.find_by_id params[:id]
	@title = @project.name
	@pic = params[:pic]
	erb :photo, :layout => :layout_photo
end

['/contact', '/contact.html'].each do |path|
	get path do
		@title = 'Contact'
		@label = 'Contact'
		erb :contact
	end
end

get '/add-project' do
	if settings.development?
		@title = "Admin only"
		@header = "Add Project"
		erb :add_project
	else
		redirect '/'
	end
end

get '/add-job' do
	if settings.development?
		@title = "Admin only"
		@header = "Add Job"
		erb :add_job
	else
		redirect '/'
	end
end

post '/add-project' do
	@p = Project.new
	@p.name        	= params[:name]
	@p.description 	= params[:description]
	@p.content     	= split_paragraphs params[:content]
	@p.order	   		= params[:order].to_i
	@p.status				= params[:status]
	@p.files				= split_files params[:files]
	@p.created_at  	= Time.now
	if params[:password] == SITE_PASSWORD
		@p.save
		redirect '/projects'
	else
		redirect '/add-project'
	end
end

post '/add-job' do
	@j = Job.new
	@j.company_name 		= params[:company_name]
	@j.title 						= params[:title]
	@j.start_date				= params[:start_date]
	@j.end_date					= params[:end_date]
	@j.description			= split_paragraphs params[:description]
	@j.order						= params[:order]
	if params[:password] == SITE_PASSWORD
		@j.save
		redirect '/experience'
	else
		redirect '/add-job'
	end
end

get '/downloads/*.*' do
	send_file params[:splat][0].to_s + "." + params[:splat][1].to_s
end

not_found do
	erb :err404, :layout => nil
end