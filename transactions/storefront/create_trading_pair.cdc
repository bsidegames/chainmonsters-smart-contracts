import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersStorefront from "../../contracts/ChainmonstersStorefront.cdc"
import NFTStorefront from "../../contracts/lib/NFTStorefront.cdc"

transaction() {
  let admin: &ChainmonstersStorefront.Admin
  let platformCutReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>
  let creatorCutReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>

  prepare(acct: AuthAccount) {
    self.admin = acct.borrow<&ChainmonstersStorefront.Admin>(from: /storage/ChainmonstersStorefrontAdmin) ?? panic("Couldn't borrow admin resource")
    
    self.platformCutReceiver = acct.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
    self.creatorCutReceiver = acct.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
  }

  execute {
    self.admin.addTradingPair(id: "ChainmonstersReward_FUSD", nftType: Type<@ChainmonstersRewards.NFT>(), ftVaultType: Type<@FUSD.Vault>(), royalties: [
      ChainmonstersStorefront.Royalty(
        receiver: self.platformCutReceiver,
        percentage: 0.05
      ),
      ChainmonstersStorefront.Royalty(
        receiver: self.creatorCutReceiver,
        percentage: 0.1
      )
    ])
  }
}
