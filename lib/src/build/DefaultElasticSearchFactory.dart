//  @module build 
// import { Factory } from 'pip-services3-components-node';
// import { Descriptor } from 'pip-services3-commons-node';

// import { ElasticSearchLogger } from '../log/ElasticSearchLogger';

// 
// /// Creates ElasticSearch components by their descriptors.
// /// 
// /// See [[ElasticSearchLogger]]
//  
// export class DefaultElasticSearchFactory extends Factory {
// 	public static readonly Descriptor = new Descriptor("pip-services", "factory", "elasticsearch", "default", "1.0");
// 	public static readonly ElasticSearchLoggerDescriptor = new Descriptor("pip-services", "logger", "elasticsearch", "*", "1.0");

// 	
// 	/// Create a new instance of the factory.
// 	 
// 	public constructor() {
//         super();
// 		this.registerAsType(DefaultElasticSearchFactory.ElasticSearchLoggerDescriptor, ElasticSearchLogger);
// 	}
// }