class ImportController < ApplicationController
  def request_auth

    session[:feed_url]=params[:feed]
    session[:tumblr_url]=params[:blog]

    consumer_key = "eehMnjMSA762fptNBld3RkMMeK8EirOnnYwVqVxY0Ycxpu3w4C"
    secret = "w8pNFvkvI6pPEhOhZBpl9SRTxgXYSoHIDnQUe6gbrOdU2GXygV"

    @consumer=OAuth::Consumer.new( consumer_key, secret, {
      :site => "http://www.tumblr.com",
      :scheme             => :header,
      :http_method        => :post,
      :request_token_path => "/oauth/request_token",
      :access_token_path  => "/oauth/access_token",
      :authorize_path     => "/oauth/authorize"
    })

    @request_token=@consumer.get_request_token
    session[:request_token]=@request_token

    redirect_to @request_token.authorize_url
  end

  def authorized

    @request_token = session[:request_token]

    if params[:oauth_token] && params[:oauth_verifier]
      @access_token=@request_token.get_access_token({:oauth_verifier => params[:oauth_verifier]})
      session[:access_token]=@access_token

      logger.info "Got access token"
      create_blog_migration
    else
      logger.info "Missing critical URL params"

      respond_to do |format|
        format.html # authorized.html.erb
      end
    end
  end

  def create_blog_migration
    #blog_url = "http://www.ryangerard.net/1/feed"
    #logger.info session[:feed_url]

    blog_url = session[:feed_url]
    feed = get_feed(blog_url)
    @feed_arr = parse_feed(feed)

    @feed_arr = write_posts_to_tumblr(@feed_arr)

    respond_to do |format|
      format.html # authorized.html.erb
    end
  end

  def get_feed(feed_url)

    require 'net/http'
    require 'uri'

	  uri = URI.parse(feed_url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
		  # OK
      return response.body
    else
		  logger.info "Failure getting feed at url " + feed_url
      return ''
    end

  end

  def parse_feed(feed)
    require 'xml'

    parser, parser.string = XML::Parser.new, feed
    doc, posts = parser.parse, []
    doc.find('//channel/item').each do |p|

      post = {}
      p.children.each do |f|

        if f.name == "title"
          post["title"] = f.first.content
        end

        if f.name == "pubDate"
          post["pubDate"] = f.first.content
        end

        if f.name == "encoded"
          post["encoded"] = f.first.content
        end
      end

      posts << post
    end

    return posts
  end

  def write_posts_to_tumblr(posts)

    post_success = []
    logger.info "Starting write"
    #t_url = "http://api.tumblr.com/v2/blog/ryangerard.tumblr.com/post"
    t_url =  "http://api.tumblr.com/v2/blog/" + session[:tumblr_url] + "/post"

    logger.info "tumblr url: " + t_url
    @access_token = session[:access_token]

    posts.each do |p|

      # build the POST params string
	    post_params = {
        :type => "text",
        :date => p["pubDate"].to_s,
        :title => p["title"].to_s,
        :body => p["encoded"].to_s
	    }

	    # Send the request
      logger.info "Posting new item to blog"
      response=@access_token.post(t_url, post_params)

      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
		    # OK
		    logger.info "Success!"
        post_success << post
      else
		    logger.info "Failure!"
        logger.info response.message
        logger.info response.body
      end

    end

    return post_success

  end
end
