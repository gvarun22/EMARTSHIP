/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package session;

import javax.ejb.Remote;

/**
 *
 * @author Sai
 */
@Remote
public interface ShippingCostSessionBeanRemote {

    String calculateShipping(String zipCode);
    
}
