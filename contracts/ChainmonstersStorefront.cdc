import NFTStorefront from "./lib/NFTStorefront.cdc"
import ChainmonstersRewards from "./ChainmonstersRewards.cdc"
import NonFungibleToken from "./lib/NonFungibleToken.cdc"
import FungibleToken from "./lib/FungibleToken.cdc"
import FUSD from "./lib/FUSD.cdc"

pub contract ChainmonstersStorefront {
  pub event ListingAvailable(
    storefrontAddress: Address,
    storefrontResourceID: UInt64,
    listingResourceID: UInt64,
    tradingPairId: String,
    nftType: Type,
    nftID: UInt64,
    ftVaultType: Type,
    price: UFix64
  )

  // A dictionary of supported trading pairs
  access(self) var tradingPairs: {String: TradingPair}

  pub struct TradingPair {
    pub let nftType: Type
    pub let ftVaultType: Type
    pub let royalties: [Royalty]

    pub fun getTotalRoyaltiesPercentage(): UFix64 {
      var percentageCut: UFix64 = 0.0

      for royalty in self.royalties {
        percentageCut = percentageCut + royalty.percentage
      }

      return percentageCut
    }

    init(nftType: Type, ftVaultType: Type, royalties: [Royalty]) {
      self.nftType = nftType
      self.ftVaultType = ftVaultType
      self.royalties = royalties
    }
  }

  pub struct Royalty {
    pub let receiver: Capability<&{FungibleToken.Receiver}>
    pub let percentage: UFix64

    init(receiver: Capability<&{FungibleToken.Receiver}>, percentage: UFix64) {
      self.receiver = receiver
      self.percentage = percentage
    }
  }

  // Admin resource that allows to add or remove supported trading pairs
  pub resource Admin {
    pub fun addTradingPair(id: String, nftType: Type, ftVaultType: Type, royalties: [Royalty]) {
      let pair = TradingPair(nftType: nftType, ftVaultType: ftVaultType, royalties: royalties)

      ChainmonstersStorefront.tradingPairs[id] = pair
    }

    pub fun removeTradingPair(id: String) {
      ChainmonstersStorefront.tradingPairs.remove(key: id)
    }

    pub fun createNewAdmin(): @Admin {
      return <-create Admin()
    }
  }
  
  pub fun createListing(
    storefront: &NFTStorefront.Storefront,
    nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
    ftReceiverCapability: Capability<&{FungibleToken.Receiver}>,
    tradingPairId: String,
    nftID: UInt64,
    price: UFix64
  ) {
    assert(nftProviderCapability.borrow()!.borrowNFT(id: nftID) != nil, message: "NFT is not in rewards provider collection")

    let tradingPair = self.getTradingPair(id: tradingPairId)!

    assert(tradingPair != nil, message: "TradingPair is not supported")

    // Initialize saleCuts array with the seller's cut
    var saleCuts: [NFTStorefront.SaleCut] = [NFTStorefront.SaleCut(
      receiver: ftReceiverCapability,
      amount: price * (1.0 - tradingPair.getTotalRoyaltiesPercentage())
    )]

    // For each royalty add a SaleCut to the array
    for royalty in tradingPair.royalties {
      saleCuts.append(NFTStorefront.SaleCut(
        receiver: royalty.receiver,
        amount: price * royalty.percentage
      ))
    }

    let listingResourceID = storefront.createListing(
      nftProviderCapability: nftProviderCapability,
      nftType: tradingPair.nftType,
      nftID: nftID,
      salePaymentVaultType: tradingPair.ftVaultType,
      saleCuts: saleCuts
    )

    let listing = storefront.borrowListing(listingResourceID: listingResourceID)!

    // We emit a custom ListingAvailable event to track "legit" listings with the correct cuts applied
    emit ListingAvailable(
      storefrontAddress: storefront.owner?.address!,
      storefrontResourceID: storefront.uuid,
      listingResourceID: listingResourceID,
      tradingPairId: tradingPairId,
      nftType: Type<@ChainmonstersRewards.NFT>(),
      nftID: nftID,
      ftVaultType: Type<@FUSD.Vault>(),
      price: listing.getDetails().salePrice
    )
  }

  pub fun getTradingPair(id: String): TradingPair? {
    return self.tradingPairs[id]
  }

  init() {
    self.tradingPairs = {}

    self.account.save<@Admin>(<- create Admin(), to: /storage/ChainmonstersStorefrontAdmin)
  }
}
