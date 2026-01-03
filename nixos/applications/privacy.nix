{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;

  privacyPolicy = pkgs.writeTextFile {
    name = "privacy-policy-site";
    destination = "/index.html";
    text = ''
      <!DOCTYPE html>
      <html lang="sv">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Integritetspolicy</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
          }
          h1, h2 {
            color: #111;
          }
        </style>
      </head>
      <body>

        <h1>Integritetspolicy</h1>
        <p><strong>Senast uppdaterad:</strong> [DATUM]</p>

        <h2>1. Inledning</h2>
        <p>
          Denna integritetspolicy beskriver hur <strong>[Appens namn]</strong>
          ("appen", "vi", "oss" eller "vår") hanterar information i samband med
          användning av vår applikation.
        </p>
        <p>
          Vi värnar om din integritet. Appen är utformad för att fungera
          <strong>utan att samla in, lagra eller behandla personuppgifter</strong>.
        </p>

        <h2>2. Information vi samlar in</h2>
        <p>
          Vi samlar <strong>inte in några personuppgifter</strong>.
        </p>
        <p>Detta innebär bland annat att vi inte:</p>
        <ul>
          <li>samlar in namn, e-postadresser, telefonnummer eller annan identifierande information</li>
          <li>lagrar information från sociala mediekonton</li>
          <li>spårar användare över olika webbplatser eller tjänster</li>
          <li>säljer eller delar data med tredje part</li>
        </ul>

        <h2>3. Tredjepartstjänster</h2>
        <p>
          Appen kan använda tredjepartstjänster såsom <strong>Facebook eller Instagram (Meta)</strong>
          enbart för autentisering eller för att utföra funktioner som användaren själv initierar.
        </p>
        <p>
          Vi lagrar inte någon information som returneras från dessa tjänster längre än vad som
          krävs för att utföra den aktuella funktionen.
        </p>
        <p>
          All autentisering och behörighetshantering sker enligt respektive
          tredjeparts egna integritetspolicys.
        </p>

        <h2>4. Cookies och spårning</h2>
        <p>
          Vi använder <strong>inga cookies, analysverktyg, spårningspixlar eller liknande tekniker</strong>
          för att identifiera eller följa användare.
        </p>

        <h2>5. Lagring av data</h2>
        <p>
          Eftersom vi inte samlar in eller lagrar personuppgifter sker
          <strong>ingen lagring av personlig data</strong>.
        </p>

        <h2>6. Datasäkerhet</h2>
        <p>
          Då inga personuppgifter lagras i våra system finns det ingen personlig
          information som kan utsättas för obehörig åtkomst, ändring eller spridning.
        </p>

        <h2>7. Barns integritet</h2>
        <p>
          Appen riktar sig inte till barn under 13 år och vi samlar inte medvetet
          in information från barn.
        </p>

        <h2>8. Ändringar i denna policy</h2>
        <p>
          Vi kan komma att uppdatera denna integritetspolicy vid behov.
          Eventuella ändringar publiceras på denna sida med uppdaterat datum.
        </p>

        <h2>9. Kontaktuppgifter</h2>
        <p>
          Om du har frågor om denna integritetspolicy kan du kontakta oss:
        </p>
        <p>
          <strong>E-post:</strong> [kontakt@dindomän.se]<br />
          <strong>Webbplats:</strong> [https://www.dindomän.se]
        </p>

      </body>
      </html>

    '';
  };
in
{
  services.nginx = {
    virtualHosts = {
      "${node.domains.friikod}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = "${privacyPolicy}";
      };
    };
  };
}
