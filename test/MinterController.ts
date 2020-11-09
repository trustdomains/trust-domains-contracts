import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { MaxUint256 } from 'ethers/constants'
import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ecsign } from 'ethereumjs-util'


var namehash = require('eth-ens-namehash')

import MinterController from '../build/MinterController.json'
import Registry from '../build/Registry.json'
import Resolver from '../build/Resolver.json'

chai.use(solidity)


describe('MinterController', () => {
  const provider = new MockProvider({
    hardfork: 'istanbul',
    mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
    gasLimit: 9999999
  })
  const [wallet, other] = provider.getWallets()

  let registry: Contract
  let controller: Contract
  let resolver : Contract
  beforeEach(async () => {
    registry = await deployContract(wallet, Registry)

    resolver = await deployContract(wallet, Resolver, [registry.address])

    controller = await deployContract(wallet, MinterController, [registry.address])

    await registry.grantMinterRole(controller.address)
  })

  it('name, symbol, roothash', async () => {
    const name = await registry.name()
    expect(name).to.eq('TD - Conflux Name Service (.cfx)')
    expect(await registry.symbol()).to.eq('TD')

    //const bnb = await registry.cfx()
    //console.log(bnb)
    
    expect(await registry.root()).to.eq('0xf60b73180d56a49cd45c6477f69b0b2505679b536bfd4fee397e6aaf4e2a4b39')

  })

  it('Resolver', async() => {
      await controller.mintURI(wallet.address, 'wallet')

      const walletHash = namehash.hash('wallet.cfx')
      await registry.setResolver(walletHash, resolver.address)

      const _resolver = await registry.resolverOf(walletHash)
      expect(_resolver).to.eq(resolver.address)

      const _owner = await registry.ownerOf(walletHash)
      expect(_owner).to.eq(wallet.address)


      //await resolver.reset(walletHash)

      await resolver.set(walletHash, "wallet.ETH.address", "0x22aCfbeC6a24756c20D41914F2caba817C0d8521")
      const ethAddress = await resolver.get(walletHash, "wallet.ETH.address")
      expect(ethAddress).to.eq('0x22aCfbeC6a24756c20D41914F2caba817C0d8521')

      
      var keys = ["wallet.ETH.address", "wallet.BTC.address"]
      var values = ['0x1AaCfbeC6a24756c20D41914F2caba817C0d8521', '1F5Htms7z9to9ns341Ww1idTrSKQ5YTfJY']
      await resolver.setMulti(walletHash, keys, values)
      const getValues = await resolver.getMulti(walletHash, keys)
      //console.log(getValues)
      expect(getValues[0]).to.eq(values[0])
      expect(getValues[1]).to.eq(values[1])

      var allKeys = await resolver.allKeys(walletHash)
      console.log(allKeys)

      var allRecords = await resolver.allRecords(walletHash)
      console.log(allRecords)
      
  })

  it('controller, mintURI, mintSubURI, mintURI, mintSubURI, burnSubURI', async () => {
    await controller.mintURI(wallet.address, 'wallet')

    const walletHash = namehash.hash('wallet.cfx')
    const tokenURI = await registry.tokenURI(walletHash)
    expect(tokenURI).to.eq('wallet.cfx')

    //sub domain
    await controller.mintSubURI(wallet.address, walletHash, 'token')
    const subWalletHash = namehash.hash('token.wallet.cfx')
    const subTokenURI = await registry.tokenURI(subWalletHash)
    expect(subTokenURI).to.eq('token.wallet.cfx')

    //use mint sub domain
    await registry.mintSubURI(wallet.address, walletHash, 'user')
    const userSubHash = namehash.hash('user.wallet.cfx')
    const userSubTokenURI = await registry.tokenURI(userSubHash)
    expect(userSubTokenURI).to.eq('user.wallet.cfx')

    //transfer domain to other
    await registry.transferURI(wallet.address, other.address, 'wallet') //transfer wallet.cfx to other
    const owner = await registry.ownerOf(walletHash)
    expect(owner).to.eq(other.address)

    //transfer subdomain
    await registry.transferSubURI(wallet.address, other.address, 'wallet', 'token')
    const owner2 = await registry.ownerOf(subWalletHash)
    expect(owner2).to.eq(other.address)

    // safe mintURI
    await controller.safeMintURI(wallet.address, 'token', "0x22")
    const tokenHash = namehash.hash('token.cfx')
    const tTokenURI = await registry.tokenURI(tokenHash)
    expect(tTokenURI).to.eq('token.cfx')

    // safe mintSubURI
    await controller.safeMintSubURI(wallet.address,tokenHash, 'wallet', "0x22")
    const tokenHash2 = namehash.hash('wallet.token.cfx')
    const tTokenURI2 = await registry.tokenURI(tokenHash2)
    expect(tTokenURI2).to.eq('wallet.token.cfx')

    //burnSubURI
    await controller.burnSubURI(tokenHash, 'wallet')
    //const tTokenURI3 = await registry.tokenURI(tokenHash2) //not exist
    //expect(tTokenURI3).to.eq('')
  }) 

  
})
