/*
 * generated by Xtext 2.10.0
 */
package com.justeat.mickeydb

import com.google.inject.Injector
import org.apache.log4j.Logger
import com.google.inject.Inject

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class MickeyLangStandaloneSetup extends MickeyLangStandaloneSetupGenerated {
	static val LOG = Logger.getLogger(MickeyLangStandaloneSetup);
		
	@Inject MickeyEnvironment mEnvironment;
			
	def static void doSetup() {
		var setup = new MickeyLangStandaloneSetup();
		setup.createInjectorAndDoEMFRegistration()
	}
		
	override createInjector() {
		var injector = super.createInjector();
		
		LOG.debug("[Mickey Standalone]");
		injector.injectMembers(this);
		mEnvironment.setStandalone(true);
		
		return injector;
	}
}
