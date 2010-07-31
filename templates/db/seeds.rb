ActiveRecord::Base.transaction do
  Dir.glob(File.join(Rails.root, %w{db seeds *.rb})).sort.each do |seed|
    Rails.logger.info("Running seed file '#{ seed }' ...")
    load(seed)
    Rails.logger.info("Seed file '#{ seed }' completed")
  end
end
