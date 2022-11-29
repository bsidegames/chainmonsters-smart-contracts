import NFTStorefront from "../../contracts/lib/NFTStorefront.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"

// This script returns the uuid of the listed NFT

pub fun main(account: Address, listingResourceID: UInt64): UInt64 {
    let storefrontRef = getAccount(account)
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public storefront from address")

    let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")
    
    return listing.uuid
}
