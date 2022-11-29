import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersStorefront from "../../contracts/ChainmonstersStorefront.cdc"
import NFTStorefront from "../../contracts/lib/NFTStorefront.cdc"

transaction(nftID: UInt64, price: UFix64) {
  let fusdVaultCapability: Capability<&FUSD.Vault{FungibleToken.Receiver}>
  let rewardsProviderCapability: Capability<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
  let storefront: &NFTStorefront.Storefront

  prepare(acct: AuthAccount) {
    let ChainmonstersRewardsCollectionProviderPrivatePath = /private/ChainmonstersRewardsCollectionProvider

    self.fusdVaultCapability = acct.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
    assert(self.fusdVaultCapability.borrow() != nil, message: "Missing or mis-typed FUSD receiver")

    if !acct.getCapability<&ChainmonstersRewards.Collection>(ChainmonstersRewardsCollectionProviderPrivatePath).check() {
      acct.link<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(ChainmonstersRewardsCollectionProviderPrivatePath, target: /storage/ChainmonstersRewardCollection)
    }

    self.rewardsProviderCapability = acct.getCapability<&ChainmonstersRewards.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(ChainmonstersRewardsCollectionProviderPrivatePath)
    assert(self.rewardsProviderCapability.borrow() != nil, message: "Missing or mis-typed ChainmonstersRewardsCollection provider")

    self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) ?? panic("Missing or mis-typed NFTStorefront Storefront")
  }

  execute {
    ChainmonstersStorefront.createListing(
      storefront: self.storefront, 
      nftProviderCapability: self.rewardsProviderCapability, 
      ftReceiverCapability: self.fusdVaultCapability, 
      tradingPairId: "ChainmonstersReward_FUSD",
      nftID: nftID, 
      price: price
    )
  }
}
