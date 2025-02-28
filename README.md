# **Decentralized Music Catalog**  
A blockchain-based music catalog built using Clarity smart contracts to manage music tracks, ownership, access rights, and metadata on a decentralized ledger.  

## **Overview**  
This smart contract provides a decentralized, immutable database for registering and managing music tracks. It ensures track ownership, metadata storage, and controlled access permissions. Additionally, it supports royalty distribution and analytics.  

## **Features**  
- **Track Registration:** Artists can add music tracks with metadata such as title, performer, length, and category.  
- **Ownership Management:** Tracks are assigned to their creators, who can transfer ownership.  
- **Access Control:** Listeners can be granted or denied access to tracks.  
- **Metadata Storage:** Includes performer name, category, and track labels/tags.  
- **Royalty Distribution:** Supports a payment system for artist compensation.  
- **Track Deletion & Modification:** Creators can update or remove their tracks.  
- **Listener Analytics:** Logs interactions for future insights.  

## **Data Structures**  
The contract uses **maps** to store music data and access rights:  
- `music-catalog` → Stores track information.  
- `access-rights` → Manages user access permissions.  
- `listener-history` → Logs listening interactions.  

### **State Variables:**  
- `track-counter` → Keeps track of the number of registered tracks.  

## **Smart Contract Functions**  

### **Track Management**  
- `register-track(name, performer, length, category, labels)` → Adds a new track to the catalog.  
- `modify-track-info(track-id, updated-name, updated-length, updated-category, updated-labels)` → Updates track details.  
- `delete-track(track-id)` → Removes a track (creator-only).  
- `change-track-owner(track-id, new-creator)` → Transfers track ownership.  

### **Access Control**  
- `check-listener-access(track-id, listener)` → Checks if a user can access a track.  
- `verify-listener-access(track-id, listener)` → Validates listener permissions.  

### **Track Queries**  
- `get-track-info(track-id)` → Retrieves full track details.  
- `lookup-track-name(track-id)` → Returns track title.  
- `lookup-track-performer(track-id)` → Returns performer name.  
- `lookup-track-category(track-id)` → Returns track genre/category.  
- `lookup-track-labels(track-id)` → Returns track metadata labels.  
- `lookup-track-creator(track-id)` → Returns the creator's address.  

### **Ownership & Permissions**  
- `is-track-in-catalog(track-id)` → Checks if a track exists.  
- `verify-track-ownership(track-id)` → Confirms if the caller owns the track.  

### **Royalty & Rewards System**  
- `distribute-royalty(track-id, payment-amount)` → Handles artist royalties.  
- `give-sharing-reward(track-id, listener)` → Rewards users for track sharing.  

## **Deployment & Usage**  

### **Prerequisites**  
- **Stacks Blockchain** → The contract runs on the Stacks network.  
- **Clarity Language** → Ensure you have a Clarity-compatible development environment.  

### **Deploying the Contract**  
1. **Set up the Stacks CLI:**  
   ```sh
   npm install -g @stacks/cli
   ```
2. **Deploy the contract:**  
   ```sh
   stacks deploy clarity-contracts/music-catalog.clar
   ```
3. **Interact with the contract using Clarity REPL or a Stacks API.**  

## **Contributing**  
Contributions are welcome! Please follow these steps:  
1. Fork the repository.  
2. Create a feature branch (`git checkout -b feature-name`).  
3. Commit changes (`git commit -m "Add new feature"`).  
4. Push to the branch (`git push origin feature-name`).  
5. Open a pull request.  
 
