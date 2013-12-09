/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package session;
import java.net.UnknownHostException;
import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.MongoClient;
import com.mongodb.MongoException;

import javax.ejb.Stateless;

/**
 *
 * @author Sai
 */
@Stateless
public class ShippingCostSessionBean implements ShippingCostSessionBeanRemote {

    @Override
    public String calculateShipping(String zipCode) {

		String shippingCost = null;
		try {
			int zip = Integer.parseInt(zipCode);
			
			// connect to the mongodb
			MongoClient mongo = new MongoClient("localhost", 27017);

			// get the database
			DB db = mongo.getDB("emart");

			// get the collection(table)
			DBCollection table = db.getCollection("shipping_details");

			/*
			 * BasicDBObject searchQuery = new BasicDBObject().append("zipcode",
			 * "60607"); DBCursor cursor = table.find(searchQuery);
			 * 
			 * 
			 * while(cursor.hasNext()) { System.out.println(cursor.next()); }
			 */

			/*
			 * while (cursor.hasNext()) { String
			 * str=cursor.curr().get("60607").toString();
			 * System.out.println(str); }
			 */

			BasicDBObject searchQuery = new BasicDBObject().append("zipcode",
					zip);
			BasicDBObject field = new BasicDBObject();

			field.put("shipping_cost", 1);
			DBCursor cursor = table.find(searchQuery, field);

			while (cursor.hasNext()) {
				BasicDBObject obj = (BasicDBObject) cursor.next();
				shippingCost = obj.getString("shipping_cost");
			}

		}
		catch(NumberFormatException e) { 
			e.printStackTrace();
		}
		catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		}

		return shippingCost;
	}

    /*
    @Override
    public String calculateShipping(String zipCode) {
        String shippingCost = null;

		try {

			// connect to the mongodb
			MongoClient mongo = new MongoClient("localhost", 27017);

			// get the database
			DB db = mongo.getDB("emart");

			// get the collection(table)
			DBCollection table = db.getCollection("emart");
                        BasicDBObject searchQuery = new BasicDBObject().append("zipcode",
					zipCode);
			BasicDBObject field = new BasicDBObject();

			field.put("shipping_cost", 1);
			DBCursor cursor = table.find(searchQuery, field);

			while (cursor.hasNext()) {
				BasicDBObject obj = (BasicDBObject) cursor.next();
				shippingCost = obj.getString("shipping_cost");
			}
		}
		catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		}
		return shippingCost;
    }*/
}
