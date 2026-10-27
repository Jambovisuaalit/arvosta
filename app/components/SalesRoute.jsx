'use client';
import {useState} from 'react';
import route from '../../data/ville-route-2026-10-27.json';

export default function SalesRoute({prospects=[],visits=[],onRecordVisit,onOpenCrm,busy=false}){
  const [selected,setSelected]=useState({});
  const [result,setResult]=useState({});
  const [notes,setNotes]=useState({});
  const [saving,setSaving]=useState(null);
  const [error,setError]=useState('');
  const [success,setSuccess]=useState('');
  const recorded=(stop)=>visits.find(v=>v.notes?.includes('[ARVOSTA-ROUTE-2026-10-27:'+stop.id+']'));
  const eligible=prospects.filter(p=>p.contact_status==='approved'&&!p.is_test);
  async function save(stop){
    const prospect=eligible.find(p=>p.id===selected[stop.id]);
    if(!prospect)return setError('Valitse CRM:ssä kontaktointiin hyväksytty yritys.');
    if(recorded(stop))return setError('Tämä reittikäynti on jo kirjattu.');
    setError('');setSuccess('');setSaving(stop.id);
    try{
      await onRecordVisit({prospect_id:prospect.id,result:result[stop.id]||'attempt',notes:'[ARVOSTA-ROUTE-2026-10-27:'+stop.id+'] '+(notes[stop.id]||'').trim()});
      setSuccess(prospect.company_name+' – käynti tallennettu CRM:ään.');
    }catch(e){setError(e.message||'Tallennus epäonnistui.');}
    finally{setSaving(null);}
  }
  const count=route.stops.filter(recorded).length;
  return <section className="sectionGap">
    <div className="card"><h2>Villen myyntireitti · 27.10.2026</h2>
      <p>Alkaen {route.startTime} · {route.area} · Kauppakartanonkatu → Easton</p>
      <p><strong>CRM:ään kirjatut käynnit: {count}/{route.stops.length}</strong></p>
      <p>Kontaktoi vain yrityksiä, joiden CRM-tila on hyväksytty. Varmista yrityksen henkilöllisyys ennen kirjausta. Aikataulu on arvio.</p>
      <button type="button" onClick={onOpenCrm}>Avaa yritysten CRM-tarkistus</button>
      {' '}<a href="https://www.google.com/maps/dir/?api=1&origin=Kauppakartanonkatu%2026%2C%20Helsinki&destination=Easton%20Helsinki%2C%20Kauppakartanonkatu%203%2C%20Helsinki&travelmode=walking" target="_blank" rel="noopener noreferrer">Avaa kartalla</a>
      {error&&<p role="alert">{error}</p>}{success&&<p role="status">{success}</p>}
    </div>
    <div className="grid2 sectionGap">{route.stops.map(stop=>{
      const visit=recorded(stop);
      const exact=prospects.filter(p=>p.company_name?.trim().toLocaleLowerCase('fi')===stop.name.toLocaleLowerCase('fi'));
      const blocked=exact.some(p=>p.contact_status==='blocked');
      return <article key={stop.id} className="card formStack">
        <div className="cardHeading"><h3>{stop.time} · {stop.name}</h3><span>{visit?'Kirjattu CRM:ään':'Suunniteltu'}</span></div>
        <p>{stop.address}</p>
        <p>{blocked?'CRM:ssä estetty samanniminen yritys – tarkista ennen mitään yhteydenottoa.':exact.length?'CRM:ssä samanniminen yritys – varmista vastaavuus.':'Ei tarkkaa nimiosumaa CRM:ssä – tarkista ennen yhteydenottoa.'}</p>
        {visit?<p>Kirjattu {new Date(visit.happened_at).toLocaleString('fi-FI')}</p>:<>
          <label>Vahvistettu CRM-yritys
            <select className="input" value={selected[stop.id]||''} onChange={e=>setSelected(a=>({...a,[stop.id]:e.target.value}))}>
              <option value="">Valitse hyväksytty yritys</option>
              {eligible.map(p=><option key={p.id} value={p.id}>{p.company_name}</option>)}
            </select>
          </label>
          <label>Käynnin tulos
            <select className="input" value={result[stop.id]||'attempt'} onChange={e=>setResult(a=>({...a,[stop.id]:e.target.value}))}>
              <option value="attempt">Käyntiyritys</option><option value="contact">Kontakti</option><option value="demo">Esittely</option><option value="quote">Tarjous</option>
            </select>
          </label>
          <label>Havainto / jatkotoimi
            <textarea className="input" maxLength={1000} value={notes[stop.id]||''} onChange={e=>setNotes(a=>({...a,[stop.id]:e.target.value}))}/>
          </label>
          <button type="button" disabled={busy||saving!==null||blocked||!selected[stop.id]} onClick={()=>save(stop)}>{saving===stop.id?'Tallennetaan…':'Tallenna käynti CRM:ään'}</button>
        </>}
      </article>;
    })}</div>
  </section>;
}