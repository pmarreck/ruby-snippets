module Assistly::AlterAssociatedRecordCountAtomically
  # The idea here is to update the associated counter cache column on an associated
  # record (usually a belongs_to) with a direct atomic database update that doesn't
  # run callbacks or validations and respects the optimistic lock field by default.
  # It will not load the associated object into memory if it's not already loaded,
  # and if it is loaded, it will reload it unless it's changed, in which case it will
  # simply make the in-memory attributes correspond with the ones written to disk. This
  # should trigger a StaleObjectError if this record is later saved by another process
  # which could theoretically overwite the record with an outdated count.
  def alter_associated_record_count_atomically_without_callbacks_or_validations_respecting_optimistic_locking(params={})
    params[:primary] ||= self
    this = params[:primary]
    params[:optimistically_locked] = this.class.lock_optimistically unless params[:optimistically_locked]==false
    ol = params[:optimistically_locked]
    dir = params[:direction]
    col = params[:column]
    assoc = params[:association]
    tnu = Time.now.utc
    klass = assoc.to_s.singularize.capitalize.constantize
    num_updated = klass.where(["? IS NOT NULL", col]).update_all(["`#{col}` = `#{col}`#{dir}1#{', `lock_version` = `lock_version`+1' if ol}, updated_at = ?", tnu], {id: this.send("#{assoc}_id"), })
    if num_updated==0 # it was NULL, so recalc it
      klass.reset_counters(this.send("#{assoc}_id"), this.class.to_s.underscore.pluralize)
    end
    if this.association(assoc).loaded?
      assoc_r = this.send(assoc)
      if assoc_r.changed?
        assoc_r.send(col).send("#{dir}=", 1)
        assoc_r.lock_version += 1 if ol
        assoc_r.updated_at = tnu
      else
        assoc_r.reload
      end
    end
  end

  def increment_associated(assoc, col)
    alter_associated_record_count_atomically_without_callbacks_or_validations_respecting_optimistic_locking(direction: :+, association: assoc, column: col)
  end

  def decrement_associated(assoc, col)
    alter_associated_record_count_atomically_without_callbacks_or_validations_respecting_optimistic_locking(direction: :-, association: assoc, column: col)
  end
end
