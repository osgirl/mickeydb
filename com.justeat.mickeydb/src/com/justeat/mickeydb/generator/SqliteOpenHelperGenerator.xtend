package com.justeat.mickeydb.generator

import com.google.inject.Inject
import com.justeat.mickeydb.generator.SqliteDatabaseSnapshot
import com.justeat.mickeydb.generator.SqliteDatabaseStatementGenerator
import com.justeat.mickeydb.mickeyLang.MickeyFile

import static extension com.justeat.mickeydb.ModelUtil.*
import static extension com.justeat.mickeydb.Strings.*
import com.justeat.mickeydb.MickeyDatabaseModel
import com.justeat.mickeydb.mickeyLang.DDLStatement

class SqliteOpenHelperGenerator {
		@Inject extension SqliteDatabaseStatementGenerator
		
		def CharSequence generate(MickeyDatabaseModel model) '''
				«var snapshot = model.snapshot»
				/*
				 * Generated by Mickey DB
				 */
				package «model.packageName»;
				
				import android.content.Context;
				import android.database.sqlite.SQLiteDatabase;
				import com.justeat.mickeydb.MickeyOpenHelper;
				import com.justeat.mickeydb.Migration;
				
				«IF model.migrations.size > 0»
				«FOR migration : model.migrations»
				import «model.packageName».migrations.Default«model.databaseName.pascalize»Migration«migration.name.pascalize»;
				«ENDFOR»
				«ENDIF»
				
				public class Default«model.databaseName.pascalize()»OpenHelper extends MickeyOpenHelper {
					public static final int VERSION = «model.migrations.length»;
				
					public interface Sources {
						«FOR table : snapshot.tables»
						String «table.name.underscore.toUpperCase» = "«table.name»";
						«ENDFOR»
						«FOR view : snapshot.views»
						String «view.name.underscore.toUpperCase» = "«view.name»";
						«ENDFOR»
						«FOR table : model.initTables»
						String «table.name.underscore.toUpperCase» = "«table.name»";
						«ENDFOR»
						«FOR view : model.initViews»
						String «view.name.underscore.toUpperCase» = "«view.name»";
						«ENDFOR»
					}
				
					public Default«model.databaseName.pascalize()»OpenHelper(Context context, String databaseFilename) {
						super(context, databaseFilename, null, VERSION);
					}

					@Override
					public void onCreate(SQLiteDatabase db) {
						applyMigrations(db, 0, VERSION);
					}
					
					«IF !model.initTables.isEmpty || !model.initViews.isEmpty»
					@Override
					public void onOpen(SQLiteDatabase db) {
						super.onOpen(db);
						
						«model.initTables.filter(DDLStatement).generateStatements»
						«model.initViews.filter(DDLStatement).generateStatements»
					}
					«ENDIF»
				
					@Override
					protected Migration createMigration(int version) {
						«IF model.migrations.size > 0»
						«var version = -1»
						switch(version) {
							«FOR migration : model.migrations»
							case «version=version+1»:
								return create«model.databaseName.pascalize»Migration«migration.name.pascalize»();
							«ENDFOR»
							default:
								throw new IllegalStateException("No migration for version " + version);
						}
						«ELSE»
						throw new IllegalStateException("No migrations for any version");
						«ENDIF»
					}
					
					«IF model.migrations.size > 0»
					«FOR migration : model.migrations»
					protected Migration create«model.databaseName.pascalize»Migration«migration.name.pascalize»() {
						return new Default«model.databaseName.pascalize»Migration«migration.name.pascalize»();
					}
					«ENDFOR»
					«ENDIF»
				}
		'''
				
		def CharSequence generateStub(MickeyDatabaseModel model, SqliteDatabaseSnapshot snapshot) '''
				/*
				 * Generated by Mickey DB
				 */
				package «model.packageName»;
				
				import android.content.Context;
				import «model.packageName».Abstract«model.databaseName.pascalize()»OpenHelper;

				
				public class «model.databaseName.pascalize()»OpenHelper extends Abstract«model.databaseName.pascalize()»OpenHelper {
					public «model.databaseName.pascalize()»OpenHelper(Context context, String databaseFilename) {
						super(context, databaseFilename);
					}
				}
		'''
}