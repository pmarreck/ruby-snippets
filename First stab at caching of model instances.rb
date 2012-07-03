def current_site(memoize = true)
	# (assumes "subdomain" and "domain" are available from URL information, this code may need to be tweaked)
  @current_site = nil unless memoize
	@current_site ||= Site.allocate.init_with('attributes' =>
		Rails.cache.fetch("Site#{subdomain}.#{domain}") do
			Site.find_by_subdomain_and_domain(domain, subdomain).attributes
		end
  )
end

# This will get you a fully instantiated Site object that never touched the DB.
# Then you just need an observer on Site to delete the cache if anything happens to the Site instance. Or figure out a key generation expiry method that takes into account updated_at, or whatever (but I think that would require maintaining a last_updated_at cached value for the site, plus additional fetching.)
# Not sure if this could hook into expire_cache_observer...
# But in theory this would never even touch the database (unless the cache key didn't exist)
# and would only touch memcache once per request.
# And only cache Site instance attributes, and not associations.
# Note that this way of doing it was only available recently, like after Rails 3.
# There is probably a way to extend this into some kind of module that could be included in model classes to force their instances to be cached in the same way.
# I know that "allocate" is called on any Find (interestingly, "new" is never called on finds), so maybe hook into that via inheritance or other mechanism.
