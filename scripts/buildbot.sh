buildbot_init() {
    template_add_sub BUILDBOT_MASTER_ENABLE
    template_add_sub BUILDBOT_SLAVE_ENABLE
    template_add_sub BUILDBOT_BASE_DIR
    template_add_sub BUILDBOT_MASTER_DIR
    template_add_sub BUILDBOT_SLAVE_DIR
    template_add_sub BUILDBOT_LOG_DIR
}

buildbot_setup() {
    debug "    Creating buildbot config"
    buildbot_init

    run_user buildbot create-master $BUILDBOT_MASTER_DIR
    run_user cp -a $BUILDBOT_MASTER_DIR/master.cfg.sample \
	$BUILDBOT_MASTER_DIR/master.cfg
    run_user \
	buildslave create-slave $BUILDBOT_SLAVE_DIR localhost:9989 \
	    example-slave pass
}

