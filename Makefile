release:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make release <tagname>"; \
		exit 1; \
	fi
	$(eval TAG := $(filter-out $@,$(MAKECMDGOALS)))
	git tag -f $(TAG)
	git push origin -f $(TAG)

%:
	@:
