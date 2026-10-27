'use client';
import {useEffect,useState} from 'react';

const STEPS=[
 {title:'Tervetuloa ARVOSTAan',text:'Tässä opit myyntikäynnin viisi vaihetta. Opastus ei luo asiakkaita, tarjouksia tai muita tietoja.',page:'home',action:'Avaa työpöytä'},
 {title:'1. Esittele tuote',text:'Avaa Esittely ja näytä asiakkaalle telineet, QR- ja NFC-toiminta sekä hinnat. Varmista tuotteen sisältö ennen lupausta.',page:'demo',action:'Siirry esittelyyn'},
 {title:'2. Lisää asiakas',text:'Avaa Yrityskäynnit (CRM). Etsi yritys ensin, jotta et luo kaksoiskappaletta. Lisää uusi asiakas tarvittaessa.',page:'crm',action:'Avaa CRM'},
 {title:'3. Luo tarjous',text:'Avaa Tarjous, valitse asiakas, tuote ja lisätelineet. Tallenna tarjous ennen PDF:n lataamista. Tarkista tarjousnumero, hinnat ja ehdot.',page:'calculator',action:'Avaa tarjous'},
 {title:'4. Lataa PDF',text:'Avaa Tarjoukset, valitse tallennettu tarjous ja lataa PDF. Tarkista, että numero, yritys, rivit ja loppusumma vastaavat tallennettua tarjousta.',page:'documents',action:'Avaa tarjoukset'},
 {title:'5. Kirjaa jatkotoimi',text:'Palaa CRM:ään ja kirjaa käynnin tulos, muistiinpanot sekä seuraavan yhteydenoton aika. Ylläpitäjä tarkistaa tarjouksen ja tapahtumat erikseen.',page:'crm',action:'Avaa CRM'}
];
export default function Onboarding({userId,onNavigate}){
 const [step,setStep]=useState(-1);
 useEffect(()=>{if(!userId)return;try{if(localStorage.getItem('arvosta:onboard:v1:'+userId)!=='done')setStep(0)}catch{setStep(0)}},[userId]);
 const finish=()=>{try{localStorage.setItem('arvosta:onboard:v1:'+userId,'done')}catch{}setStep(-1)};
 return <>
 <button type="button" className="button text" onClick={()=>setStep(0)} aria-label="Avaa käyttöopastus">Ohje</button>
 {step>=0&&<div className="onboardBackdrop" role="presentation"><section className="onboardDialog" role="dialog" aria-modal="true" aria-labelledby="onboardTitle" aria-describedby="onboardText">
 <div className="onboardTop"><span>PIKAOPASTUS · {step+1}/{STEPS.length}</span><button type="button" className="button text" onClick={finish}>Sulje</button></div>
 <div className="onboardProgress" aria-hidden="true"><div style={{width:((step+1)/STEPS.length*100)+'%'}}/></div>
 <h2 id="onboardTitle">{STEPS[step].title}</h2><p id="onboardText">{STEPS[step].text}</p>
 <div className="onboardActions"><button type="button" className="button outline" disabled={step===0} onClick={()=>setStep(v=>v-1)}>Edellinen</button>
 <button type="button" className="button primary" onClick={()=>{onNavigate(STEPS[step].page);if(step===STEPS.length-1)finish();else setStep(v=>v+1)}}>{step===STEPS.length-1?'Valmis':STEPS[step].action+' →'}</button></div>
 <small>Voit avata opastuksen uudelleen yläreunan Ohje-painikkeesta.</small>
 </section></div>}
 </>;
}
