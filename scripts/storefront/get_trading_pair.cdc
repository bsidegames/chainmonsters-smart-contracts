import FungibleToken from "../../contracts/lib/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/lib/NonFungibleToken.cdc"
import FUSD from "../../contracts/lib/FUSD.cdc"
import ChainmonstersRewards from "../../contracts/ChainmonstersRewards.cdc"
import ChainmonstersStorefront from "../../contracts/ChainmonstersStorefront.cdc"
import NFTStorefront from "../../contracts/lib/NFTStorefront.cdc"

pub fun main(id: String): ChainmonstersStorefront.TradingPair? {
  return ChainmonstersStorefront.getTradingPair(id: id)
}
