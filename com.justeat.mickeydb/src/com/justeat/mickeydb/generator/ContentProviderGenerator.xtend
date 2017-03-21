package com.justeat.mickeydb.generator

import com.justeat.mickeydb.generator.SqliteDatabaseSnapshot
import com.justeat.mickeydb.mickeyLang.ActionStatement
import com.justeat.mickeydb.mickeyLang.ContentUri
import com.justeat.mickeydb.mickeyLang.ContentUriParamSegment
import static extension com.justeat.mickeydb.ModelUtil.*
import static extension com.justeat.mickeydb.Strings.*
import com.justeat.mickeydb.MickeyDatabaseModel
import com.justeat.mickeydb.ContentUris
import com.justeat.mickeydb.mickeyLang.ColumnType

class ContentProviderGenerator {
		def CharSequence generate(MickeyDatabaseModel model, ContentUris content) '''
			«var snapshot = model.snapshot»
			/*
			 * Generated by Mickey DB
			 */
			package «model.packageName»;
			
			import android.content.Context;
			import android.content.UriMatcher;
			import android.net.Uri;
			import java.util.Set;
			import com.justeat.mickeydb.MickeyContentProvider;
			import com.justeat.mickeydb.MickeyOpenHelper;
			import com.justeat.mickeydb.ContentProviderActions;
			«FOR uri : content.uris»
			import «model.packageName».actions.«uri.name.pascalize»Actions;			
			«ENDFOR»
	
			public abstract class Abstract«model.databaseName.pascalize»ContentProvider extends MickeyContentProvider {
			
				«var counter=-1»
				«FOR uri : content.uris»
				public static final int «uri.id» = «counter=counter+1»;
				«ENDFOR»
				public static final int NUM_URI_MATCHERS = «content.uris.size»;
				
				public static final String DATABASE_NAME = "«model.databaseName»";
				public static final int DATABASE_VERSION = «model.version»;
				
				public Abstract«model.databaseName.pascalize»ContentProvider(boolean debug) {
					super(debug);
				}

				public Abstract«model.databaseName.pascalize»ContentProvider() {
					super(false);
				}
			
				@Override
			    protected UriMatcher createUriMatcher() {
			        final UriMatcher matcher = new UriMatcher(UriMatcher.NO_MATCH);
			        final String authority = «model.databaseName.pascalize»Contract.CONTENT_AUTHORITY;
			
					«FOR uri : content.uris»
					matcher.addURI(authority, "«uri.pathPattern»", «uri.id»);
					«ENDFOR»
			
			        return matcher;
			    }
			    
			    @Override
			    protected String[] createContentTypes() {
					String[] contentTypes = new String[NUM_URI_MATCHERS];

					«FOR uri : content.uris»
					«IF uri.directory»
					contentTypes[«uri.id»] = «model.databaseName.pascalize»Contract.«uri.type.pascalize».CONTENT_TYPE;
					«ELSE»
					contentTypes[«uri.id»] = «model.databaseName.pascalize»Contract.«uri.type.pascalize».ITEM_CONTENT_TYPE;
					«ENDIF»
					«ENDFOR»

					return contentTypes;
			    }
			
				@Override
				protected MickeyOpenHelper createOpenHelper(Context context, String databaseFilename) {
			        return new Default«model.databaseName.pascalize»OpenHelper(context, databaseFilename);
				}
				
				@Override
				protected int getDatabaseVersion() {
			        return DATABASE_VERSION;
				}
				
				@Override
				protected String getDatabaseName() {
			        return DATABASE_NAME;
				}
				
				@Override
				protected Set<Uri> getRelatedUris(Uri uri) {
					return «model.databaseName.pascalize»Contract.REFERENCING_VIEWS.get(uri);
				}
			    
			    @Override
			    protected ContentProviderActions createActions(int id) {
			    	switch(id) {
			    		«FOR uri : content.uris»
			    		case «uri.id»:
			    			return create«uri.name.pascalize»Actions();
						«ENDFOR»
						default:
							throw new UnsupportedOperationException("Unknown id: " + id);
			    	}
			    }
			    
				«FOR uri : content.uris»
				protected ContentProviderActions create«uri.name.pascalize»Actions() {
					return new «uri.name.pascalize»Actions();
				}				
				«ENDFOR»
			}
		'''
		
		def asString(ActionStatement action) {
			var builder = new StringBuilder()
			
			builder.append(action.type)
			
			for(seg : action.uri.segments) {
				builder.append("/")
				if(seg instanceof ContentUriParamSegment) {
					if(seg.param.inferredColumnType == ColumnType::TEXT) {
						builder.append("*")
					} else {
						builder.append("#")
					}
					
				} else {
					builder.append(seg.name)
				}
			}
			
			return builder.toString
		}

	
		def generateContentTypeConstantReference(ActionStatement action, String databaseName) {
			if(action.unique) {
				return databaseName.pascalize + "Contract." + action.type.name.pascalize + ".ITEM_CONTENT_TYPE";
			} else {
				return databaseName.pascalize + "Contract." + action.type.name.pascalize + ".CONTENT_TYPE";
			}
		}
		
		def generateDatabaseFileVersion(MickeyDatabaseModel model) {
			if(model.version == 0) {
				return ""
			}
			
			return "." + model.version
		}

			
		def CharSequence generateStub(MickeyDatabaseModel model, SqliteDatabaseSnapshot snapshot) '''
			/*******************************************************************************
			 * Copyright (c) 2012, Robotoworks Limited
			 * All rights reserved. This program and the accompanying materials
			 * are made available under the terms of the Eclipse Public License v1.0
			 * which accompanies this distribution, and is available at
			 * http://www.eclipse.org/legal/epl-v10.html
			 * 
			 *******************************************************************************/
			package «model.packageName»;
			
			import «model.packageName».Abstract«model.databaseName.pascalize»ContentProvider;
			
			public class «model.databaseName.pascalize»ContentProvider extends Abstract«model.databaseName.pascalize»ContentProvider {}
		'''
}