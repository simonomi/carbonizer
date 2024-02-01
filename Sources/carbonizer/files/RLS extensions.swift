extension RLS.Binary.Kaseki {
	init(_ kaseki: RLS.Kaseki?) {
		guard let kaseki else {
			self = RLS.Binary.Kaseki(isEntry: 0, unknown1: 0, unbreakable: 0, destroyable: 0, unknown2: 0, unknown3: 0, unknown4: 0, unknown5: 0, fossilImage: 0, rockImage: 0, fossilConfig: 0, rockConfig: 0, buyPrice: 0, sellPrice: 0, unknown6: 0, unknown7: 0, fossilName: 0, unknown8: 0, time: 0, passingScore: 0, unknown9: 0, unknownsCount: 0, unknownsOffset: 0x44, unknowns: [])
			return
		}
		
		isEntry = kaseki.isEntry ? 1 : 0
		unknown1 = kaseki.unknown1 ? 1 : 0
		unbreakable = kaseki.unbreakable ? 1 : 0
		destroyable = kaseki.destroyable ? 1 : 0
		
		unknown2 = kaseki.unknown2
		unknown3 = kaseki.unknown3
		unknown4 = kaseki.unknown4
		unknown5 = kaseki.unknown5
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		fossilConfig = kaseki.fossilConfig
		rockConfig = kaseki.rockConfig
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		unknown6 = kaseki.unknown6
		unknown7 = kaseki.unknown7
		fossilName = kaseki.fossilName
		unknown8 = kaseki.unknown8
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		unknown9 = kaseki.unknown9
		
		unknownsCount = kaseki.unknownsCount
		unknownsOffset = kaseki.unknownsOffset
		unknowns = kaseki.unknowns
	}
}
