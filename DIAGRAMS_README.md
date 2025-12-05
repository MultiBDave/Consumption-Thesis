# Diagrams README

This folder contains PlantUML sources for the project's UML and ER diagrams:

- `UML.puml` — Class diagram showing core models and helpers (CarEntry, FuelEntry, ServiceItem, Reminder, ExtraCost, and helper classes).
- `ER.puml` — Entity-Relationship diagram showing collections and foreign-key relationships (Firestore-oriented view).

How to render
--------------
You can render the `.puml` files to PNG/SVG using any of the following methods.

1) VS Code + PlantUML extension
- Install the "PlantUML" extension by jebbs (or equivalent).
- Open the `.puml` file and preview (Alt+D or use the preview button).
- Export to PNG/SVG via the extension UI.

2) PlantUML CLI (Java)
- Download `plantuml.jar` from https://plantuml.com/download
- From PowerShell run (from the repo root):

```powershell
# render both diagrams as PNG
java -jar path\to\plantuml.jar UML.puml ER.puml

# render a specific diagram, output into current folder
java -jar path\to\plantuml.jar -tpng UML.puml
```

3) Online server (quick preview)
- You can paste the PlantUML text into https://plantuml.com/plantuml
- Or use PlantUML server endpoints to generate images programmatically.

Notes
-----
- The `.puml` sources are textual and can be edited to reflect model changes.
- PlantUML supports multiple diagram types; these files use class/entity notation for clarity.
- If you prefer SVG output for inclusion in a thesis, use `-tsvg` with the PlantUML jar.

Example command (PowerShell):

```powershell
# Render PNG and SVG for UML.puml
java -jar C:\tools\plantuml\plantuml.jar -tpng UML.puml
java -jar C:\tools\plantuml\plantuml.jar -tsvg UML.puml
```

If you want, I can also generate a PDF containing both diagrams or convert them to vector images and add them under a `docs/` folder.