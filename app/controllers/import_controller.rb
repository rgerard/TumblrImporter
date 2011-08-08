class ImportController < ApplicationController
  def request_auth
    require 'oauth/consumer'

    consumer_key = "eehMnjMSA762fptNBld3RkMMeK8EirOnnYwVqVxY0Ycxpu3w4C"
    secret = "w8pNFvkvI6pPEhOhZBpl9SRTxgXYSoHIDnQUe6gbrOdU2GXygV"
    @consumer=OAuth::Consumer.new( consumer_key, secret, {
      :site => "http://www.tumblr.com/oauth/request_token"
    })

    @request_token=@consumer.get_request_token
    session[:request_token]=@request_token

    auth_url = "http://www.tumblr.com/oauth/authorize?oauth_token=" + @request_token.token
    redirect_to auth_url
  end

  def authorized
    require 'oauth/consumer'

    @request_token = session[:request_token]
    logger.info "Using request token " + @request_token.token
    @request_token.consumer.options[:site] = "http://www.tumblr.com"

    @access_token=@request_token.get_access_token

    t_url = "http://api.tumblr.com/v2/blog/ryangerard.tumblr.com/post"

    # build the POST params string
    post_params = {
      :type => "text",
      :title => "testing",
      :body => "more testing"
	  }

    # Send the request
    logger.info "Posting new item to blog"
    @response=@access_token.post(t_url, post_params)

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
	    # OK
		  logger.info "Success!"
    else
	    logger.info "Failure!"
      logger.info response.to_s
    end

  end

  def create
    request_auth()
    blog_url = "http://www.ryangerard.net/1/feed"

    feed = get_feed(blog_url)
    feed_arr = parse_feed(feed)

    feed_arr.each do |p|
      logger.info "+++++++++++++++++++++++"
      logger.info p["title"].to_s
      logger.info p["pubDate"].to_s
    end

    write_posts_to_tumblr(feed_arr)

    respond_to do |format|
      format.html # create.html.erb
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
		  logger.info "Success!"
      return response.body
    else
		  logger.info "Failure!"
      return ''
    end

  end

  def parse_feed(feed)
    require 'xml'

    parser, parser.string = XML::Parser.new, feed
    doc, posts = parser.parse, []
    doc.find('//channel/item').each do |p|
      logger.info "===================="
      logger.info p.name

      post = {}
      p.children.each do |f|
        logger.info "----------------------"
        logger.info f.name
        logger.info f.first.content

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

    require 'net/http'
    require 'uri'

    t_url = "http://api.tumblr.com/v2/blog/ryangerard.tumblr.com//"

	  uri = URI.parse(t_url)
	  http = Net::HTTP.new(uri.host, 80)

    count = 0;
    posts.each do |p|
      logger.info "&&&&&&&&&&&&&&&&&&&&&&"

      break if count > 0

      # build the POST params string
	    post_params = {
        :email => "ryan.gerard@gmail.com",
        :pass => "rgerard00",
        :type => "regular",
        :date => p["pubDate"].to_s,
        :title => p["title"].to_s,
        :body => p["encoded"].to_s,
        :format => "html"
	    }

	    # Create the POST request
	    request = Net::HTTP::Post.new(uri.request_uri)
	    request.body = post_params

	    # Send the request
	    response = http.request(request)

      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
		    # OK
		    logger.info "Success!"
      else
		    logger.info "Failure!"
        logger.info response.to_s
      end

      count = count + 1
    end

  end
end
