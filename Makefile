# <makefile>
# Objects: refdata, package
# Actions: clean, build, deploy
help:
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
	    IFS=$$'#' ; \
	    help_split=($$help_line) ; \
	    help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
	    printf "%-30s %s\n" $$help_command $$help_info ; \
	done
# </makefile>

#server:=https://staging.openchs.org
#port:=443
token:=somethinghere
port:= $(if $(port),$(port),8021)
server:= $(if $(server),$(server),http://localhost)
server_url:=$(server):$(port)

su:=$(shell id -un)
org_name=JSS

define _curl
	curl -X $(1) $(server_url)/$(2) -d $(3)  \
		-H "Content-Type: application/json"  \
		-H "ORGANISATION-NAME: $(org_name)"  \
		$(if $(token),-H "AUTH-TOKEN: $(token)",)
	@echo
	@echo
endef

auth:
	$(if $(poolId),$(eval token:=$(shell node scripts/token.js $(poolId) $(clientId) $(username) $(password))))
	echo $(token)

auth_live:
	make auth poolId=$(OPENCHS_PROD_USER_POOL_ID) clientId=$(OPENCHS_PROD_APP_CLIENT_ID) username=admin password=$(OPENCHS_PROD_ADMIN_USER_PASSWORD)

# <create_org>
create_org: ## Create JSS org and user+privileges
	psql -U$(su) openchs < create_organisation.sql
# </create_org>

# <refdata>
deploy_concepts:
	$(call _curl,POST,concepts,@concepts.json)
	$(call _curl,POST,concepts,@registrationConcepts.json)
	$(call _curl,POST,concepts,@child/enrolmentConcepts.json)

deploy_catchments:
	$(call _curl,POST,locations,@locations.json)
	$(call _curl,POST,catchments,@catchments.json)

deploy_refdata: deploy_concepts deploy_catchments
	$(call _curl,POST,forms,@registrationForm.json)
	$(call _curl,PATCH,forms,@child/enrolmentAdditions.json)
	$(call _curl,DELETE,forms,@child/enrolmentDeletions.json)
	$(call _curl,POST,operationalEncounterTypes,@operationalModules/operationalEncounterTypes.json)
	$(call _curl,POST,operationalPrograms,@operationalModules/operationalPrograms.json)
	$(call _curl,POST,formMappings,@formMappings.json)

# </refdata>

# <deploy>
deploy: deploy_refdata deploy_rules##

deploy_rules: ##
	node index.js "$(server_url)" "$(token)"

deploy_rules_live:
	make auth deploy_rules poolId=$(OPENCHS_PROD_USER_POOL_ID) clientId=$(OPENCHS_PROD_APP_CLIENT_ID) username=admin password=$(OPENCHS_PROD_ADMIN_USER_PASSWORD) server=https://server.openchs.org port=443
# </deploy>

create_deploy: create_org deploy ##

deploy_staging: deps
	make auth deploy poolId=ap-south-1_tuRfLFpm1 clientId=93kp4dj29cfgnoerdg33iev0v server=https://staging.openchs.org port=443 username=admin password=$(STAGING_ADMIN_USER_PASSWORD)
# </deploy>

deps:
	npm i

# <package>
#build_package: ## Builds a deployable package
#	rm -rf output/impl
#	mkdir -p output/impl
#	cp registrationForm.json catchments.json deploy.sh output/impl
#	cd output/impl && tar zcvf ../openchs_impl.tar.gz *.*
# </package>
