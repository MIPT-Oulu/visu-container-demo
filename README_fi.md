# VISU-konttilaskentaopas — Sydämen vajaatoiminnan ennustaminen kliinisistä tiedoista

Tässä esimerkissä näytetään, kuinka kliinisiin mittauksiin perustuva koneoppimisluokitin koulutetaan ja sen tuloksia tulkitaan sydämen vajaatoimintapotilaiden aineistolla. 
Opas käsittelee datan jakamisen, mallin kouluttamisen ristiinvalidoinnilla, arviointimittarit sekä muuttujien tärkeysanalyysin SHAP-menetelmällä.

Analyysi suoritetaan kontissa, joka sisältää kaikki tarvittavat ohjelmistot, jolloin ympäristö toimii samalla tavalla riippumatta käytetystä tietokoneesta ja voidaan helposti siirtää tietoturvalliseen laskentaympäristöön.

---

## Sisältö

| Tiedosto                 | Kuvaus                                  |
|--------------------------|-----------------------------------------|
| `VISU_tutorial_fi.ipynb` | Jupyter-muistikirja tulosten laskentaan |
| `Dockerfile_fi`          | Määrittelee konttiympäristön            |
| `requirements.txt`       | Konttiin asennettavat Python-paketit    |

---

## Esivaatimukset

- [Docker](https://docs.docker.com/get-docker/) asennettuna ja käynnissä (Docker Desktop, Docker Compose tai Docker Engine)
- Vähintään muutama gigatavu vapaata levytilaa rakennettavalle Docker-kuvalle (5.27GB) ja sen siirrolle (1.26 GB)
- Vaihetta 3 varten (sensitiivinen data / VISU-ympäristö): voimassa oleva tutkimuslupa, [käyttäjäympäristötilaus](https://eforms.oulu.fi/fi) ja SSH-avain rekisteröitynä osoitteessa https://u.oulu.fi/sshkeys
---

## Vaihe 1 — Lataa aineisto

Lataa sydämen vajaatoiminta-aineisto UCI Machine Learning Repository -palvelusta:

https://archive.ics.uci.edu/dataset/519/heart+failure+clinical+records

Pura zip-tiedosto. Siirrä tiedosto `heart_failure_clinical_records_dataset.csv` repositorion `data`-kansioon. 
Varmista, että käyttäjälläsi on kansioon käyttöoikeus (Properties → Permissions).

---

## Vaihe 2 — Rakenna Docker-levykuva

Varmista, että Docker on käynnissä, ja rakenna kuva projektikansiossa:

```bash
docker build -t visu-demo-image:jupyter-notebook .
```

Tämä lataa jupyter/scipy-notebook-peruskuvan ja asentaa kaikki tarvittavat paketit. Ensimmäisellä kerralla tämä voi kestää muutamia minuutteja.
Kuvan nimi on `visu-demo-image` ja tunniste (tag) on `jupyter-notebook`.

---

## (Valinnainen) — Aja muistikirja paikallisesti Docker-kontissa

Käynnistä JupyterLab alla olevalla komennolla. Voit tarvittaessa korvata `./data`-kansion sillä kansiolla, johon tallensit aineiston.

```bash
docker run --rm -p 8888:8888 -v ./data:/code/data visu-demo-image:jupyter-notebook
```

Avaa terminaaliin tulostuva URL-osoite (alkaa muotoa `http://127.0.0.1:8888/...`) selaimessa ja avaa sitten `VISU_tutorial.ipynb`.
Voit käydä muistikirjan läpi ajamalla solut yksitellen peräkkäin tai kaikki kerralla.

> Parametri `-v ./data:/code/data` tuo paikallisen data-kansion kontin sisälle polkuun `/code/data`.
> Aineistotiedoston tulee löytyä kontin sisällä polusta `/code/data/heart_failure_clinical_records_dataset.csv`.

> Tulostettu URL-osoite sisältää pääsytokenin (pitkä merkkijono `?token=`-parametrin jälkeen). 
> Tämä on JupyterLabin tapa tunnistaa käyttäjä. Erillistä kirjautumista ei tarvita, kun avaat koko tulostetun linkin sellaisenaan.
---

## Vaihe 3 — Aja Apptainer-kontti sensitiivisen datan ympäristössä

VISU:ssa ja muilla tutkimusalustoilla, joilla käytetään [Apptaineria](https://apptainer.org/), Docker-kuva muunnetaan ensin Apptainer-kuvaksi (`.sif`-tiedosto).
Sensitiivistä dataa ei sisällytetä kuvaan.
Oulun yliopiston tutkimuspalvelut toimittavat sen VISU-henkilöstölle tutkimusluvan mukaisesti, minkä jälkeen se on saatavilla laskentaympäristössä polussa `data/import`.

**Vie Docker-kuva .tar-tiedostoksi**

```bash
docker save -o visu-demo-image.tar visu-demo-image:jupyter-notebook
```

**Siirrä kuva (visu-demo-image.tar) tutkimusympäristöön SFTP:llä**. Siirrä myös aineisto demoa varten.

- Tiedostot siirretään VISU:un suojatulla SFTP-yhteydellä (secure shell file transfer protocol).
- Luo SSH-avainpari
  - Komentorivi → `ssh-keygen -t ed25519` → valinnainen tiedostopolku → valinnainen salasana → toista salasana
    https://u.oulu.fi/sshkeys: kirjaudu Oulun yliopiston tunnuksilla
- Lisää aiemmin tallennettu julkinen avain (`id_ed25519.pub`) kopioimalla sen sisältö tekstikenttään
- Oletuskansio on yleensä `home/.ssh` tai `C:/Users/käyttäjänimi/.ssh`
- Siirrä tiedostot komentorivillä komennolla `sftp käyttäjä@files.visu.oulu.fi`
- Listaa käytettävissä olevat ympäristöt komennolla `ls` ja siirry laskentaympäristön import-kansioon komennolla `cd visu-202xxxxx/import`
- Siirrä tiedostot import-kansioon nykyisestä paikallisesta kansiosta: `put <polku/tiedostonimi>`

**Muunna Docker-kuva:**
```bash
apptainer build visu-demo-container.sif docker-archive:visu-demo-image.tar
```

**Aja muistikirja:**
```bash
apptainer exec \
    --bind ./data:/code/data \
    --env JUPYTER_RUNTIME_DIR=./tmp/jupyter-runtime \
    --env JUPYTER_DATA_DIR=./tmp/jupyter-data \
    visu-demo-container.sif \
    jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/code
```

> `--bind`-valitsin mahdollistaa pääsyn paikalliseen datahakemistoon kontin sisällä.
> Myös koodihakemisto voitaisiin bind-mountata tähän `,`-erottimella.
> `--env`-valitsimet ohjaavat Jupyterin ajonaikaisen ja datahakemiston `/tmp`-polkuun, joka on kirjoitettavissa kontin sisällä.
> Ilman näitä Jupyter yrittää kirjoittaa kotihakemistoosi (`/users/…`), joka on VISU-ympäristössä vain luku -tilassa.
> `--notebook-dir`-valitsin asettaa JupyterLabin työskentelyhakemistoksi kontin sisäisen `/code`-hakemiston.

---

## Kontin pysäyttäminen

- **Docker:** Paina `Ctrl+C` JupyterLabia ajavassa terminaalissa, tai aja toisesta terminaalista `docker stop <container_id>` (ID löytyy komennolla `docker ps`). Jos kontti käynnistettiin `--rm`-muuttujalla, se poistetaan automaattisesti pysäytyksen yhteydessä eikä sitä tarvitse erikseen poistaa.
- **Apptainer:** Paina `Ctrl+C` JupyterLabia ajavassa terminaalissa. Apptainer-kontteja ei tarvitse poistaa erikseen.

---

## Vianetsintä

- **Portti 8888 on jo varattu:** Sulje sitä käyttävä ohjelma, tai vaihda porttiyhdistelmä, esim. `-p 8889:8888`, ja avaa sen sijaan `http://127.0.0.1:8889/...`.
- **Käyttöoikeusvirheitä konttiin sidotussa datakansiossa:** Tarkista, että paikallinen `data`-kansio on olemassa ja että käyttäjälläsi on siihen luku- ja kirjoitusoikeudet.
- **Apptainer-kuvan rakennus epäonnistuu / levytila loppuu:** `.sif`-tiedoston rakentaminen vaatii väliaikaista levytilaa lopullista kuvakokoa enemmän. Vapauta tilaa, tai aseta `APPTAINER_TMPDIR` osoittamaan kansioon, jossa on enemmän tilaa.
- **Jupyter yrittää kirjoittaa vain luku -tilassa olevaan kotihakemistoon:** Varmista, että Vaiheen 3 `--env`-muuttujat ovat mukana täsmälleen kuten esitetty; ilman niitä Jupyter kirjoittaa oletuksena kotihakemistoosi, joka on VISU-ympäristössä vain luku -tilassa.

---

## Tuki

Sensitiivisen datan VISU-ympäristöön ja käyttöoikeuksiin tai tutkimuslupiin liittyvissä kysymyksissä ota yhteyttä Oulun yliopiston VISU-ympäristön tukeen tai tutkimuspalveluihin. 

---

## Aineistoviite

Chicco, D., Jurman, G. Machine learning can predict survival of patients with heart failure from serum creatinine and ejection fraction alone. *BMC Med Inform Decis Mak* **20**, 16 (2020). https://doi.org/10.1186/s12911-020-1023-5
