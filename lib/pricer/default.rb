require 'yaml'

class Pricer
  class Default
    def initialize(source)
      begin
        @source = YAML.load_file(source)
      rescue StandardError => e
        raise BadPricingFormatError, "could not load the yaml file, #{e.message}"
      end

      # now we dont need the name part of each entry, so rework
      # to a hash index by code, with an hash of bundle/price pairs
      build_code_index(@source)
    end

    def price(type, amount)
      logger.debug("type #{type}")
      logger.debug("amount #{amount}")
      price_for_type(@type_bundle_prices[type].keys.sort, amount, @type_bundle_prices[type])
    end

    # returns the cost of bundles of flowers that total to flowers_required, given pricing groups
    # returns -1 if its not possible to bundle the flowers_required without any left overs

    # bundles is the list of bundles sizes for this kind of flower, in ascending order
    # flowers required is the total of flowers required for this order
    # groups is the hash of bundle->price pairs
    def price_for_type(bundles, flowers_required, groups)
      logger.debug "on entry"
      logger.debug "bundles #{bundles.inspect}"
      logger.debug "flowers_required #{flowers_required.inspect}"
      logger.debug "groups #{groups.inspect}"

      # ruby objects are passed by reference, need a local copy to make sure we
      # pop just in this context, not also what is passed to us
      local_bundles = bundles.dup

      # how many bundles of bundle_size can we make
      bundle_size = local_bundles.pop

      logger.debug "processing for bundle_size |#{bundle_size}|"

      # we have no more bundles to make, do we still have flowers to fulfill the order ?
      # this can happen when we can fulfill an order with smaller bundles but not bigger bundles
      if bundle_size.nil?
        # fractional bundles aren't allowed - return failure sentinal
        # flowers_required == 0  means no more flowers required, so no more money to add to order
        logger.debug "no more bundles, flowers_required == #{flowers_required}"
        return flowers_required == 0 ? 0 : -1
      end

      remaining_flowers = flowers_required % bundle_size
      whole_bundles = flowers_required / bundle_size
      
      logger.debug "whole_bundles #{whole_bundles}"
      logger.debug "remaining_flowers #{remaining_flowers}"

      # its possible that sub-bundles may not be possible
      # we'll reverse this assignment if that happens
      # not 100% confortable with this, as it complicates the code with the reversals
      total = whole_bundles * groups[bundle_size]
      if total != 0
        components = [[whole_bundles, bundle_size, groups[bundle_size]]]
      else
        components = []
      end

      if remaining_flowers != 0 # get the price of the sub-bundles
        sub_bundles_price, sub_components = price_for_type(local_bundles, remaining_flowers, groups)

        if sub_bundles_price == -1 # cant form sub bundles with this set of bundles  
          if local_bundles.length > 0 # there are other sub-bundles we could calculate from 
            # reset the price we got with the current bundle
            total -= whole_bundles * groups[bundle_size]
            components.pop

            # and recalculate with just sub_bundles - local_bundles has had the current bundle already popped off
            # so it consists of either just sub_bundles or an empty set
            sub_total, sub_components = price_for_type(local_bundles, flowers_required, groups)

            if sub_total == -1 and whole_bundles > 1
              logger.debug "degenerate case"
              # degenerate case
              # say we have the following bundle sizes (same as tulips)
              # 3, 5, 9
              # using the above strategy, this sub_bundle call fails for 11 tulips,
              # as it tries to fulfill with 2 lots of 5 tulips
              # and ends up detecting a fractional bunch and returning the failure sentinal.
              # but this order can be fulfilled with 1 bunch of 5, and 2 bunches of 3

              # so we retry, using one bunch from our current bundle size, and see if we can fulfill with the remaining
              # sub-bundle sizes
              whole_bundles -= 1
              total += whole_bundles * groups[bundle_size] # the one bundle
              components << [whole_bundles, bundle_size, groups[bundle_size]]
              # and recalculate
              sub_total, sub_components = price_for_type(local_bundles, flowers_required - (whole_bundles * bundle_size), groups)
              logger.debug "after retry - sub_total #{sub_total} - sub_components #{sub_components}"

              if sub_total == -1 # still cant form a sub-bundle
                logger.debug "still fails for degenerate - reverse"
                # reverse the assignment
                total -= whole_bundles * groups[bundle_size]
                components.pop
                return -1
              end
            elsif sub_total == -1 # and a single bundle
              # reverse the assignment
              total -= whole_bundles * groups[bundle_size]
              components.pop
              return -1  
            end
            # valid sub_bundle - falls through to final statement
            total += sub_total
            sub_components.each do |sub_component|
              components << sub_component
            end
          else
            return -1 # no more possible valid sub-bundles, return sentinal
          end
        else # valid sub-bundles
          total += sub_bundles_price
          sub_components.each do |sub_component|
            components << sub_component
          end
        end
      end

      [total, components]
    end

    class BadPricingFormatError < StandardError; end

    private
    # note we could do some checking to see that increasing
    # bundle sizes progressively decrease the unit price
    # but lets leave that for a diffferent pricing strategy
    # implementation :)

    def build_code_index(source)
      @type_bundle_prices = {}
      source.each do |name, data|
        code = data['code']
        type_bundle_prices[code] = {}
        data['bundles'].each do |group, price|
          type_bundle_prices[code][group.to_i] = price.to_i
        end
      end
    end

    attr_accessor :type_bundle_prices
  end
end
