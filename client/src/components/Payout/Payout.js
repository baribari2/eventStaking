import { React, useState } from 'react';
import ReactDOM from 'react-dom';
import './Payout.css';

import { ethers } from 'ethers';
import RSVP from '../../artifacts/contracts/RSVP.sol/RSVP.json';

function Payout() {

  const [eventId, setEventId] = useState();

  const rsvpAddress = '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0';

  async function payout(e) {
    e.preventDefault();
    if (typeof window.ethereum !== 'undefined'){
      const [owner] = await window.ethereum.request({ method: 'eth_requestAccounts' })
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(rsvpAddress, RSVP.abi, signer);

      const payoutButton = await contract.payout('0')

      console.log('payout complete');
    }
  }

  return( 
    <div>
      <form className='payout-form' onSubmit={payout}>
        <div className='payout-form-container'>
          <label className='payout-form-label'>Enter EventId: </label>
          <input type='text' className='payout-id' onChange={ e => setEventId({ eventId: e.target.value }) }/>
          <button className='payout-button' type='submit'>Payout</button>
        </div>
      </form>
    </div>
  )
}

export default Payout;
