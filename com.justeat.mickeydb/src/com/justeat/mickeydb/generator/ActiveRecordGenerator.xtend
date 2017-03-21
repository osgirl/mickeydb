package com.justeat.mickeydb.generator

import com.justeat.mickeydb.mickeyLang.ColumnDef
import com.justeat.mickeydb.mickeyLang.ColumnType
import com.justeat.mickeydb.mickeyLang.CreateTableStatement
import com.justeat.mickeydb.mickeyLang.CreateViewStatement
import com.justeat.mickeydb.mickeyLang.ResultColumn
import com.justeat.mickeydb.mickeyLang.TableDefinition

import static extension com.justeat.mickeydb.ModelUtil.*
import static extension com.justeat.mickeydb.Strings.*

class ActiveRecordGenerator {
		def CharSequence generate(String packageName, String databaseName, TableDefinition stmt) '''
			/*
			 * Generated by Mickey DB
			 */
			package «packageName»;

			import android.content.ContentResolver;
			import android.database.Cursor;
			import android.os.Bundle;
			import android.os.Parcel;
			import android.os.Parcelable;
			import android.net.Uri;
			import «packageName».«databaseName.pascalize»Contract.«stmt.name.pascalize»;
			import «packageName».«databaseName.pascalize»Contract.«stmt.name.pascalize».Builder;
			import com.justeat.mickeydb.util.Closeables;
			import com.justeat.mickeydb.ActiveRecord;
			import com.justeat.mickeydb.ActiveRecordFactory;
			import com.justeat.mickeydb.Mickey;
			import com.justeat.mickeydb.AbstractValuesBuilder;
			
			public class «stmt.name.pascalize»Record extends ActiveRecord implements Parcelable {

				private static final ActiveRecordFactory<«stmt.name.pascalize»Record> sFactory = new ActiveRecordFactory<«stmt.name.pascalize»Record>() {
					@Override
					public «stmt.name.pascalize»Record create(Cursor c) {
						return fromCursor(c);
					}
					
					@Override
					public String[] getProjection() {
						return PROJECTION;
					}

			        @Override
					public Uri getContentUri() {
					    return «stmt.name.pascalize».CONTENT_URI;
					}
				};

			public static ActiveRecordFactory<«stmt.name.pascalize»Record> getFactory() {
					return sFactory;
				}

			    public static final Parcelable.Creator<«stmt.name.pascalize»Record> CREATOR 
			    	= new Parcelable.Creator<«stmt.name.pascalize»Record>() {
			        public «stmt.name.pascalize»Record createFromParcel(Parcel in) {
			            return new «stmt.name.pascalize»Record(in);
			        }
			
			        public «stmt.name.pascalize»Record[] newArray(int size) {
			            return new «stmt.name.pascalize»Record[size];
			        }
			    };
			    
			    public static final String[] PROJECTION = {
			    	«generateProjectionArrayMembers(stmt)»
			    };
			    
			    public interface Indices {
			    	«generateProjectionIndicesMembers(stmt)»
			    }
			    
			    «generateFields(stmt)»
			    
			    @Override
			    protected String[] _getProjection() {
			    	return PROJECTION;
			    }
			    
			    «generateAccessors(stmt)»
			    
			    public «stmt.name.pascalize»Record() {
			    	super(«stmt.name.pascalize».CONTENT_URI);
				}
				
				private «stmt.name.pascalize»Record(Parcel in) {
			    	super(«stmt.name.pascalize».CONTENT_URI);
			    	
					setId(in.readLong());
					
					«generateParcelDeserializationStatements(stmt)»
				}
				
				@Override
				public int describeContents() {
				    return 0;
				}
				
				@Override
				public void writeToParcel(Parcel dest, int flags) {
					dest.writeLong(getId());
					«generateParcelSerializationStatements(stmt)»
				}
				
				@Override
				protected AbstractValuesBuilder createBuilder() {
					Builder builder = «stmt.name.pascalize».newBuilder();

					«generateBuilderStatements(stmt)»
					
					return builder;
				}
				
			    @Override
				public void makeDirty(boolean dirty){
					«generateMakeDirtyStatements(stmt)»
				}

				@Override
				protected void setPropertiesFromCursor(Cursor c) {
					setId(c.getLong(Indices._ID));
					«generateSetFromCursorStatements(stmt)»
				}
				
				public static «stmt.name.pascalize»Record fromCursor(Cursor c) {
				    «stmt.name.pascalize»Record item = new «stmt.name.pascalize»Record();
				    
					item.setPropertiesFromCursor(c);
					
					item.makeDirty(false);
					
				    return item;
				}
				
				public static «stmt.name.pascalize»Record fromBundle(Bundle bundle, String key) {
					bundle.setClassLoader(«stmt.name.pascalize»Record.class.getClassLoader());
					return bundle.getParcelable(key);
				}
				
				public static «stmt.name.pascalize»Record get(long id) {
				    Cursor c = null;
				    
				    ContentResolver resolver = Mickey.getContentResolver();
				    
				    try {
				        c = resolver.query(«stmt.name.pascalize».CONTENT_URI.buildUpon()
						.appendPath(String.valueOf(id)).build(), PROJECTION, null, null, null);
				        
				        if(!c.moveToFirst()) {
				            return null;
				        }
				        
				        return fromCursor(c);
				    } finally {
				        Closeables.closeSilently(c);
				    }
				}
			}
		'''
		
		def dispatch generateSetFromCursorStatements(CreateTableStatement stmt) '''
			«FOR item : stmt.columnDefs.filter([!it.name.equals("_id")])»
			«var col = item as ColumnDef»
			«IF col.type == ColumnType::BOOLEAN»
			set«col.name.pascalize»(c.getInt(Indices.«col.name.underscore.toUpperCase») > 0);
			«ELSEIF col.type == ColumnType::BLOB»
			set«col.name.pascalize»(c.getBlob(Indices.«col.name.underscore.toUpperCase»));
			«ELSE»
			set«col.name.pascalize»(c.get«col.type.toJavaTypeName.pascalize»(Indices.«col.name.underscore.toUpperCase»));
			«ENDIF»
			«ENDFOR»
		'''
		
		def dispatch generateSetFromCursorStatements(CreateViewStatement stmt) '''
			«var cols = stmt.viewResultColumns»
			«FOR item : cols.filter([!it.name.equals("_id")])»
			«var col = item as ResultColumn»
			«var type = col.inferredColumnType»
			«IF type == ColumnType::BOOLEAN»
			set«col.name.pascalize»(c.getInt(Indices.«col.name.underscore.toUpperCase») > 0);
			«ELSEIF type == ColumnType::BLOB»
			set«col.name.pascalize»(c.getBlob(Indices.«col.name.underscore.toUpperCase»));
			«ELSE»
			set«col.name.pascalize»(c.get«type.toJavaTypeName.pascalize»(Indices.«col.name.underscore.toUpperCase»));
			«ENDIF»
			«ENDFOR»
		'''

		
		def dispatch generateMakeDirtyStatements(CreateTableStatement stmt) '''
			«FOR col : stmt.columnDefs.filter([!it.name.equals("_id")])»
			m«col.name.pascalize»Dirty = dirty;
			«ENDFOR»
		'''
		
		def dispatch generateMakeDirtyStatements(CreateViewStatement stmt) '''
			«var cols = stmt.viewResultColumns»
			«FOR col : cols.filter([!it.name.equals("_id")])»
			m«col.name.pascalize»Dirty = dirty;
			«ENDFOR»
		'''

		
		def dispatch generateBuilderStatements(CreateTableStatement stmt) '''
			«FOR col : stmt.columnDefs.filter([!it.name.equals("_id")])»
			if(m«col.name.pascalize»Dirty) {
				builder.set«col.name.pascalize»(m«col.name.pascalize»);
			}
			«ENDFOR»
		'''
		
		def dispatch generateBuilderStatements(CreateViewStatement stmt) '''
			«var cols = stmt.viewResultColumns»
			«FOR col : cols.filter([!it.name.equals("_id")])»
			if(m«col.name.pascalize»Dirty) {
				builder.set«col.name.pascalize»(m«col.name.pascalize»);
			}
			«ENDFOR»
		'''

		
		def dispatch generateParcelSerializationStatements(CreateTableStatement stmt) '''
			«FOR item : stmt.columnDefs.filter([!it.name.equals("_id")])»
			«var col = item as ColumnDef»
			«IF col.type == ColumnType::BOOLEAN»
			dest.writeInt(m«col.name.pascalize» ? 1 : 0);
			«ELSEIF col.type == ColumnType::BLOB»
			dest.writeByteArray(m«col.name.pascalize»);
			«ELSE»
			dest.write«col.type.toJavaTypeName.pascalize»(m«col.name.pascalize»);
			«ENDIF»
			«ENDFOR»
			dest.writeBooleanArray(new boolean[] {
				«FOR col : stmt.columnDefs.filter([!it.name.equals("_id")]) SEPARATOR ","»
				m«col.name.pascalize»Dirty
				«ENDFOR»
			});
		'''
		
		def dispatch generateParcelSerializationStatements(CreateViewStatement stmt) '''
			«var cols = stmt.viewResultColumns»
			«FOR item : cols.filter([!it.name.equals("_id")])»
			«var col = item as ResultColumn»
			«var type = col.inferredColumnType»
			«IF type == ColumnType::BOOLEAN»
			dest.writeInt(m«col.name.pascalize» ? 1 : 0);
			«ELSEIF type == ColumnType::BLOB»
			dest.writeByteArray(m«col.name.pascalize»);
			«ELSE»
			dest.write«type.toJavaTypeName.pascalize»(m«col.name.pascalize»);
			«ENDIF»
			«ENDFOR»
			dest.writeBooleanArray(new boolean[] {
				«FOR col : cols.filter([!it.name.equals("_id")]) SEPARATOR ","»
				m«col.name.pascalize»Dirty
				«ENDFOR»
			});
		'''

		
		def dispatch generateParcelDeserializationStatements(CreateTableStatement stmt) '''
				«var counter=-1»
				«FOR item : stmt.columnDefs.filter([!it.name.equals("_id")])»
				«var col = item as ColumnDef»
				«IF col.type == ColumnType::BOOLEAN»
				m«col.name.pascalize» = (in.readInt() > 0);
				«ELSEIF col.type == ColumnType::BLOB»
				m«col.name.pascalize» = in.createByteArray();
				«ELSE»
				m«col.name.pascalize» = in.read«col.type.toJavaTypeName.pascalize»();
				«ENDIF»
				«ENDFOR»
				
				boolean[] dirtyFlags = new boolean[«stmt.columnDefs.size - 1»];
				in.readBooleanArray(dirtyFlags);
				«FOR col : stmt.columnDefs.filter([!it.name.equals("_id")])»
				m«col.name.pascalize»Dirty = dirtyFlags[«counter = counter + 1»];
				«ENDFOR»
		'''
		
		def dispatch generateParcelDeserializationStatements(CreateViewStatement stmt) '''
				«var counter=-1»
				«var cols = stmt.viewResultColumns»
				«FOR item : cols.filter([!it.name.equals("_id")])»
				«var col = item as ResultColumn»
				«var type = col.inferredColumnType»
				«IF type == ColumnType::BOOLEAN»
				m«col.name.pascalize» = (in.readInt() > 0);
				«ELSEIF type == ColumnType::BLOB»
				m«col.name.pascalize» = in.createByteArray();
				«ELSE»
				m«col.name.pascalize» = in.read«type.toJavaTypeName.pascalize»();
				«ENDIF»
				«ENDFOR»
				
				boolean[] dirtyFlags = new boolean[«cols.size - 1»];
				in.readBooleanArray(dirtyFlags);
				«FOR col : cols.filter([!it.name.equals("_id")])»
				m«col.name.pascalize»Dirty = dirtyFlags[«counter = counter + 1»];
				«ENDFOR»
		'''

		
		def dispatch getName(CreateTableStatement statement) {
			statement.name
		}
		
		def dispatch getName(CreateViewStatement statement) {
			statement.name
		}

		
		def dispatch generateProjectionArrayMembers(CreateTableStatement stmt) '''
			«FOR col : stmt.columnDefs SEPARATOR ','»
			«stmt.name.pascalize».«col.name.underscore.toUpperCase»
			«ENDFOR»
		'''
		
		def dispatch generateProjectionArrayMembers(CreateViewStatement stmt) '''
			«FOR col : stmt.viewResultColumns SEPARATOR ','»
			«stmt.name.pascalize».«col.name.underscore.toUpperCase»
			«ENDFOR»
		'''

		def dispatch generateProjectionIndicesMembers(CreateTableStatement stmt) '''
			«var counter=-1»
			«FOR col : stmt.columnDefs»
				int «col.name.underscore.toUpperCase» = «counter = counter + 1»;
			«ENDFOR»
		'''
		
		def dispatch generateProjectionIndicesMembers(CreateViewStatement stmt) '''
			«var counter=-1»
			«FOR col : stmt.viewResultColumns»
				int «col.name.underscore.toUpperCase» = «counter = counter + 1»;
			«ENDFOR»
		'''
		
		def dispatch generateFields(CreateTableStatement stmt) '''
			«FOR item : stmt.columnDefs.filter([!it.name.equals("_id")])»
			«var col = item as ColumnDef»
			private «col.type.toJavaTypeName» m«col.name.pascalize»;
			private boolean m«col.name.pascalize»Dirty;
			«ENDFOR»
		'''
		

		
		def dispatch generateFields(CreateViewStatement stmt) '''
			«FOR item : stmt.viewResultColumns.filter([!it.name.equals("_id")])»
			«var col = item as ResultColumn»
			«var type = col.inferredColumnType»
			private «type.toJavaTypeName» m«col.name.pascalize»;
			private boolean m«col.name.pascalize»Dirty;
			«ENDFOR»
		'''

		def dispatch generateAccessors(CreateTableStatement stmt) '''
			«FOR item : stmt.columnDefs.filter([!it.name.equals("_id")])»
			«var col = item as ColumnDef»
			public void set«col.name.pascalize»(«col.type.toJavaTypeName» «col.name.camelize») {
				m«col.name.pascalize» = «col.name.camelize»;
				m«col.name.pascalize»Dirty = true;
			}
			
			public «col.type.toJavaTypeName» get«col.name.pascalize»() {
				return m«col.name.pascalize»;
			}
			
			«ENDFOR»
		'''
		
		def dispatch generateAccessors(CreateViewStatement stmt) '''
			«FOR item : stmt.viewResultColumns.filter([!it.name.equals("_id")])»
			«var col = item as ResultColumn»
			«var type = col.inferredColumnType»
			public void set«col.name.pascalize»(«type.toJavaTypeName» «col.name.camelize») {
				m«col.name.pascalize» = «col.name.camelize»;
				m«col.name.pascalize»Dirty = true;
			}
			
			public «type.toJavaTypeName» get«col.name.pascalize»() {
				return m«col.name.pascalize»;
			}
			«ENDFOR»
		'''
}