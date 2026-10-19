# -*- coding: utf-8 -*-
"""
manage_crane_db.py
İnanır Kule Vinç - Sürücü Arıza Kodu, Parametre ve Servis Formu Veritabanı Yönetim Aracı
Bu script, DataModel.json dosyasına komut satırından veya programatik olarak
yeni arıza kodları, parametreler ve servis formları eklemenizi, listelemenizi ve yönetmenizi sağlar.
"""

import json
import os
import sys
from datetime import datetime

DATA_FILE = os.path.join(os.path.dirname(__file__), 'DataModel.json')

def load_data():
    if not os.path.exists(DATA_FILE):
        print(f"Hata: {DATA_FILE} bulunamadı!")
        return None
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_data(data):
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Veritabanı başarıyla kaydedildi: {DATA_FILE}")

def list_drives():
    data = load_data()
    if not data:
        return
    print("\n--- KAYITLI İNVERTER / SÜRÜCÜ MODELLERİ ---")
    for i, d in enumerate(data.get('drives', [])):
        print(f"{i+1}. ID: {d.get('id')} | Model: {d.get('name')} ({d.get('manufacturer')}) | Hata: {len(d.get('faults', []))} | Parametre: {len(d.get('parameters', []))}")

def list_services():
    data = load_data()
    if not data:
        return
    forms = data.get('serviceForms', [])
    print(f"\n--- KAYITLI KULE VİNÇ SERVİS FORMLARI ({len(forms)} Adet) ---")
    for i, s in enumerate(forms):
        print(f"{i+1}. Fiş No: {s.get('formNo')} | Tür: {s.get('type')} | Tarih: {s.get('date')} | Firma: {s.get('clientCompany')} | Şantiye: {s.get('siteName')} | Vinç: {s.get('craneBrand')} {s.get('craneModel')} | Durum: {s.get('status')}")

def add_fault(drive_id, code, title, severity="Kritik", cause="", solution=""):
    """Sürücüye yeni arıza kodu ekler."""
    data = load_data()
    if not data:
        return False
    drive = next((d for d in data.get('drives', []) if d.get('id') == drive_id), None)
    if not drive:
        print(f"Hata: '{drive_id}' kimlikli sürücü bulunamadı!")
        return False

    new_fault = {
        "code": code.strip(),
        "title": title.strip(),
        "severity": severity.strip(),
        "cause": cause.strip() or "Olası neden belirtilmemiş",
        "solution": solution.strip() or "Sahada müdahale adımı girilmemiş"
    }

    if 'faults' not in drive:
        drive['faults'] = []
    
    # Başa ekle
    drive['faults'].insert(0, new_fault)
    save_data(data)
    print(f"Başarılı: '{drive.get('name')}' modeline '{code} - {title}' hata kodu eklendi.")
    return True

def add_parameter(drive_id, code, title, recommended="-", factory="Standart", purpose="", desc=""):
    """Sürücüye yeni parametre ve ayar anlamı ekler."""
    data = load_data()
    if not data:
        return False
    drive = next((d for d in data.get('drives', []) if d.get('id') == drive_id), None)
    if not drive:
        print(f"Hata: '{drive_id}' kimlikli sürücü bulunamadı!")
        return False

    purpose_str = purpose.strip()
    if purpose_str and not purpose_str.lower().startswith("şu işe yarar:"):
        purpose_str = "Şu işe yarar: " + purpose_str

    desc_str = desc.strip()
    if desc_str and not desc_str.lower().startswith("vinç güvenlik mantığı ve ayar kılavuzu:"):
        desc_str = "Vinç güvenlik mantığı ve ayar kılavuzu: " + desc_str

    new_param = {
        "code": code.strip(),
        "title": title.strip(),
        "recommended": recommended.strip() or "-",
        "factory": factory.strip() or "Standart",
        "purpose": purpose_str or "Şu işe yarar: Vinç tork ve hız ayarı",
        "desc": desc_str or "Vinç güvenlik mantığı ve ayar kılavuzu: Güvenli kule vinç operasyonu"
    }

    if 'parameters' not in drive:
        drive['parameters'] = []

    # Başa ekle
    drive['parameters'].insert(0, new_param)
    save_data(data)
    print(f"Başarılı: '{drive.get('name')}' modeline '{code} - {title}' parametresi eklendi.")
    return True

def add_service_form(form_type, client, site, brand, model, work_done, fault_desc="", technician="İnanır Vinç Ekibi", status="Faal"):
    """Yeni servis formu oluşturur."""
    data = load_data()
    if not data:
        return False
    if 'serviceForms' not in data:
        data['serviceForms'] = []

    today_str = datetime.now().strftime("%Y%m%d")
    count = len(data['serviceForms']) + 1
    form_no = f"İKV-{today_str}-{count:02d}"

    new_form = {
        "id": f"srv-{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "formNo": form_no,
        "type": form_type,
        "date": datetime.now().strftime("%Y-%m-%d"),
        "timeStart": datetime.now().strftime("%H:%M"),
        "timeEnd": "",
        "clientCompany": client,
        "siteName": site,
        "siteLocation": "",
        "contactPerson": "",
        "contactPhone": "",
        "craneBrand": brand,
        "craneModel": model,
        "craneSerial": "",
        "craneJib": "",
        "craneHeight": "",
        "reportedFault": fault_desc,
        "detectedFault": fault_desc,
        "workDone": work_done,
        "partsReplaced": "",
        "checklist": {
            "brakeTest": True,
            "momentTest": True,
            "hoistLimit": True,
            "trolleyLimit": True,
            "slewingLimit": True,
            "eStopTest": True
        },
        "status": status,
        "technician": technician,
        "receiver": "",
        "notes": ""
    }

    data['serviceForms'].insert(0, new_form)
    save_data(data)
    print(f"Başarılı: '{form_no}' numaralı servis fişi ({form_type} - {client} / {site}) oluşturuldu.")
    return True


def edit_parameter(drive_id, code, title=None, recommended=None, factory=None, purpose=None, desc=None):
    """Mevcut bir sürücü parametresini günceller."""
    data = load_data()
    if not data:
        return False
    drive = next((d for d in data.get('drives', []) if d.get('id') == drive_id), None)
    if not drive:
        print(f"Hata: '{drive_id}' kimlikli sürücü bulunamadı!")
        return False
    param = next((p for p in drive.get('parameters', []) if p.get('code', '').lower() == code.strip().lower()), None)
    if not param:
        print(f"Hata: '{code}' parametresi bulunamadı!")
        return False
    if title is not None:
        param['title'] = title.strip()
    if recommended is not None:
        param['recommended'] = recommended.strip()
    if factory is not None:
        param['factory'] = factory.strip()
    if purpose is not None:
        p_str = purpose.strip()
        if p_str and not p_str.lower().startswith("şu işe yarar:"):
            p_str = "Şu işe yarar: " + p_str
        param['purpose'] = p_str
    if desc is not None:
        d_str = desc.strip()
        if d_str and not d_str.lower().startswith("vinç güvenlik mantığı ve ayar kılavuzu:"):
            d_str = "Vinç güvenlik mantığı ve ayar kılavuzu: " + d_str
        param['desc'] = d_str
    save_data(data)
    print(f"Başarılı: '{drive.get('name')}' modelindeki '{code}' parametresi güncellendi.")
    return True

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'list':
        list_drives()
    elif len(sys.argv) > 1 and sys.argv[1] == 'services':
        list_services()
    else:
        print("İnanır Kule Vinç Veritabanı Yönetim Aracı")
        print("Kullanım:")
        print("  python3 manage_crane_db.py list      # Sürücü modellerini listeler")
        print("  python3 manage_crane_db.py services  # Servis formlarını listeler")
        list_drives()
        list_services()