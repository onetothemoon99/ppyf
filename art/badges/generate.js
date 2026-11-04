// สร้างรูปเหรียญตรา Roblox (512x512) เป็น SVG แล้วเรนเดอร์ PNG ด้วย Chrome headless
// ใช้: node art/badges/generate.js
// เพิ่มตรา: เพิ่มขั้นใน TIERS (สีขอบ) แล้วเพิ่มแถวใน BADGES พร้อมฟังก์ชันวาดไอคอน

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const OUT = __dirname;
const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";
const INK = "#3b2a20";
const FONT = "'Arial Black','Segoe UI Black',sans-serif";

const TIERS = {
	1: { light: "#f6c08f", mid: "#c9743a", dark: "#7d3f1b", ribbon: "#b5602a", stars: 1 }, // ทองแดง
	2: { light: "#ffffff", mid: "#bcc7d6", dark: "#6f7d92", ribbon: "#7f8ea6", stars: 2 }, // เงิน
	3: { light: "#fff3a8", mid: "#ffc62e", dark: "#b8730a", ribbon: "#e0940f", stars: 3 }, // ทอง
	welcome: { light: "#ffe6f0", mid: "#ff94bb", dark: "#c94f86", ribbon: "#ee5f98", stars: 0, hearts: 3 }, // ตราพิเศษ ยินดีต้อนรับ
};

// ---------- ชิ้นส่วนพื้นฐาน ----------
function star(cx, cy, r, fill) {
	const pts = [];
	for (let i = 0; i < 10; i++) {
		const a = -Math.PI / 2 + (i * Math.PI) / 5;
		const rr = i % 2 ? r * 0.48 : r;
		pts.push(`${(cx + rr * Math.cos(a)).toFixed(1)},${(cy + rr * Math.sin(a)).toFixed(1)}`);
	}
	return `<polygon points="${pts.join(" ")}" fill="${fill}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>`;
}

function leaf(x, y, len, w, deg, fill = "url(#leaf)") {
	return `<g transform="translate(${x} ${y}) rotate(${deg})">
		<path d="M0,0 C${w},${-len * 0.25} ${w * 0.85},${-len * 0.8} 0,${-len} C${-w * 0.85},${-len * 0.8} ${-w},${-len * 0.25} 0,0Z"
			fill="${fill}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<path d="M0,${-len * 0.12} L0,${-len * 0.72}" stroke="#3f9a3c" stroke-width="6" stroke-linecap="round" fill="none"/>
	</g>`;
}

function stem(d) {
	return `<path d="${d}" fill="none" stroke="${INK}" stroke-width="26" stroke-linecap="round"/>
		<path d="${d}" fill="none" stroke="#58c04e" stroke-width="12" stroke-linecap="round"/>`;
}

function soil() {
	return `<path d="M128,348 Q256,276 384,348 Q256,382 128,348Z" fill="#8a5a35" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
		<path d="M170,334 Q256,298 330,330" fill="none" stroke="#b07a4c" stroke-width="10" stroke-linecap="round"/>`;
}

function heart(cx, cy, r, fill) {
	return `<path transform="translate(${cx} ${cy}) scale(${r / 20})" d="M0,18 C-30,-4 -20,-24 -8,-22 C-3,-21 0,-16 0,-13 C0,-16 3,-21 8,-22 C20,-24 30,-4 0,18Z"
		fill="${fill}" stroke="${INK}" stroke-width="${80 / r}" stroke-linejoin="round"/>`;
}

function bubble(x, y, r) {
	return `<circle cx="${x}" cy="${y}" r="${r}" fill="#ffffff66" stroke="#ffffff" stroke-width="5"/>
		<circle cx="${x - r * 0.3}" cy="${y - r * 0.3}" r="${r * 0.22}" fill="#fff"/>`;
}

// ปลาหันขวา จุดศูนย์กลาง 0,0 ยาวประมาณ 340
function fish(x, y, scale, deg, c) {
	return `<g transform="translate(${x} ${y}) rotate(${deg}) scale(${scale})">
		<path d="M-96,0 L-178,-62 Q-146,0 -178,62Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-40,-58 Q0,-122 58,-62Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-22,58 Q6,104 44,58Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-122,0 C-66,-82 72,-84 136,0 C72,84 -66,82 -122,0Z" fill="${c.body}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-96,20 C-40,62 62,62 118,18 C60,36 -40,38 -96,20Z" fill="${c.belly}"/>
		<path d="M48,-44 Q24,0 48,44" fill="none" stroke="${INK}" stroke-width="8" stroke-linecap="round"/>
		<path d="M-4,-8 Q-34,16 -6,32 Q2,12 -4,-8Z" fill="${c.fin}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<circle cx="84" cy="-14" r="20" fill="#fff" stroke="${INK}" stroke-width="7"/>
		<circle cx="90" cy="-13" r="10" fill="${INK}"/>
		<circle cx="94" cy="-18" r="4" fill="#fff"/>
		<path d="M114,20 Q124,24 130,14" fill="none" stroke="${INK}" stroke-width="7" stroke-linecap="round"/>
	</g>`;
}

// ---------- ไอคอนแต่ละตรา ----------
const ICONS = {
	plant1: () => `${stem("M256,330 C256,290 256,260 256,214")}
		${leaf(256, 226, 124, 62, -56)}${leaf(256, 226, 124, 62, 56)}${soil()}`,
	plant2: () => `${stem("M256,330 C256,270 256,210 256,150")}
		${leaf(256, 282, 112, 54, -72)}${leaf(256, 282, 112, 54, 72)}
		${leaf(256, 214, 104, 50, -56)}${leaf(256, 214, 104, 50, 56)}
		${leaf(256, 170, 92, 46, 0)}${soil()}`,
	plant3: () => {
		let petals = "";
		for (let i = 0; i < 14; i++) {
			petals += `<path transform="rotate(${(i * 360) / 14} 256 176)" d="M256,176 C226,136 234,96 256,84 C278,96 286,136 256,176Z"
				fill="#ffd21f" stroke="${INK}" stroke-width="7" stroke-linejoin="round"/>`;
		}
		return `${stem("M256,330 C256,290 256,250 256,190")}
			${leaf(256, 300, 106, 50, -66)}${leaf(256, 300, 106, 50, 66)}
			${petals}<circle cx="256" cy="176" r="48" fill="#7a4620" stroke="${INK}" stroke-width="8"/>
			<circle cx="256" cy="176" r="28" fill="#5a3216"/>
			<circle cx="243" cy="162" r="7" fill="#a86a35"/>${soil()}`;
	},
	welcome: () => `
		<circle cx="146" cy="214" r="19" fill="#9a6a45" stroke="${INK}" stroke-width="9"/>
		<circle cx="366" cy="214" r="19" fill="#9a6a45" stroke="${INK}" stroke-width="9"/>
		<circle cx="146" cy="215" r="8" fill="#e6b58f"/><circle cx="366" cy="215" r="8" fill="#e6b58f"/>
		<ellipse cx="256" cy="250" rx="124" ry="96" fill="#a8744c" stroke="${INK}" stroke-width="10"/>
		<ellipse cx="256" cy="284" rx="100" ry="58" fill="#f4dcc2"/>
		<path d="M176,282 L136,272 M176,296 L134,300 M336,282 L376,272 M336,296 L378,300" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>
		<ellipse cx="184" cy="274" rx="20" ry="12" fill="#ff9db4" opacity=".8"/>
		<ellipse cx="328" cy="274" rx="20" ry="12" fill="#ff9db4" opacity=".8"/>
		<circle cx="210" cy="238" r="17" fill="${INK}"/><circle cx="216" cy="232" r="6" fill="#fff"/>
		<circle cx="302" cy="238" r="17" fill="${INK}"/><circle cx="308" cy="232" r="6" fill="#fff"/>
		<ellipse cx="256" cy="264" rx="18" ry="13" fill="${INK}"/><ellipse cx="250" cy="260" rx="5" ry="3" fill="#fff"/>
		<path d="M256,277 V288 M256,288 Q238,306 220,292 M256,288 Q274,306 292,292" fill="none" stroke="${INK}" stroke-width="7" stroke-linecap="round"/>
		<ellipse cx="256" cy="158" rx="138" ry="28" fill="#f5cf6b" stroke="${INK}" stroke-width="10"/>
		<path d="M184,156 Q188,86 256,84 Q324,86 328,156 Q256,178 184,156Z" fill="#fbdf8d" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M185,132 Q256,152 327,132 L328,156 Q256,178 184,156Z" fill="#e8574a" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
		<g transform="rotate(14 396 262)">
			<circle cx="396" cy="262" r="35" fill="#a8744c" stroke="${INK}" stroke-width="9"/>
			<ellipse cx="396" cy="272" rx="15" ry="12" fill="#f4dcc2"/>
			<circle cx="376" cy="248" r="7" fill="#f4dcc2"/><circle cx="396" cy="240" r="7" fill="#f4dcc2"/><circle cx="416" cy="248" r="7" fill="#f4dcc2"/>
		</g>`,
	fish1: () => `${fish(262, 228, 0.82, -6, { body: "#ff9f43", belly: "#ffe0b0", fin: "#ff6f3c" })}`,
	fish2: () => `${fish(248, 240, 0.92, -8, { body: "#4db8ff", belly: "#d5f2ff", fin: "#2384e8" })}`,
};

// ของที่วาดหลังไอคอน
const BEHIND = {
	welcome: () => {
		let rays = "";
		for (let i = 0; i < 12; i++) rays += `<path transform="rotate(${i * 30} 370 112)" d="M360,62 L370,30 L380,62Z" fill="#ffc62e"/>`;
		return `<g clip-path="url(#disc)">${rays}<circle cx="370" cy="112" r="44" fill="#ffd84f"/></g>`;
	},
};

// ของที่ไม่ใส่ขอบสติกเกอร์ (ฟองอากาศ)
const EXTRAS = {
	fish1: () => `${bubble(360, 128, 17)}${bubble(394, 176, 11)}`,
	fish2: () => `${bubble(384, 150, 21)}${bubble(350, 104, 14)}${bubble(148, 124, 15)}`,
};

// ---------- ประกอบเหรียญ ----------
// รูปวาดเต็มวง (ตรายินดีต้อนรับ ใช้รูปปกเกม art/badges/source)
function artImage(b) {
	const data = fs.readFileSync(path.join(OUT, "source", b.art)).toString("base64");
	return `<g clip-path="url(#disc)"><image href="data:image/webp;base64,${data}" x="${b.artX}" y="${b.artY}" width="${b.artSize}" height="${b.artSize}"/></g>`;
}

function background(cat) {
	if (cat === "plant") {
		return `<circle cx="256" cy="256" r="206" fill="url(#sky)"/>
			<g clip-path="url(#disc)">
				<ellipse cx="170" cy="150" rx="46" ry="20" fill="#fff" opacity=".85"/>
				<ellipse cx="350" cy="118" rx="36" ry="16" fill="#fff" opacity=".85"/>
				<path d="M40,320 Q170,250 280,306 T480,290 V480 H40Z" fill="#a8e36f"/>
				<path d="M40,360 Q200,300 480,350 V480 H40Z" fill="#7fce55"/>
			</g>`;
	}
	return `<circle cx="256" cy="256" r="206" fill="url(#water)"/>
		<g clip-path="url(#disc)" fill="none" stroke="#ffffff55" stroke-width="9" stroke-linecap="round">
			<path d="M60,140 q40,-22 80,0 t80,0"/>
			<path d="M280,92 q36,-20 72,0 t72,0"/>
			<path d="M300,340 q36,-20 72,0 t72,0"/>
			<path d="M60,316 q36,-20 72,0"/>
		</g>`;
}

function studs() {
	let out = "";
	for (let i = 0; i < 28; i++) {
		const deg = i * (360 / 28);
		// ด้านบนเว้นให้ดาว ด้านล่างเว้นให้ริบบิ้น
		if (deg < 44 || deg > 316 || (deg > 118 && deg < 242)) continue;
		const a = ((deg - 90) * Math.PI) / 180;
		out += `<circle cx="${(256 + 232 * Math.cos(a)).toFixed(1)}" cy="${(256 + 232 * Math.sin(a)).toFixed(1)}" r="7" fill="#ffffffaa" stroke="#00000033" stroke-width="2"/>`;
	}
	return out;
}

function rankStars(tier) {
	if (TIERS[tier].hearts) {
		return heart(198, 46, 19, "#ff5f8f") + heart(256, 35, 23, "#ff5f8f") + heart(314, 46, 19, "#ff5f8f");
	}
	const n = TIERS[tier].stars;
	const gap = 17; // องศาระหว่างดาว
	let out = "";
	for (let i = 0; i < n; i++) {
		const deg = (i - (n - 1) / 2) * gap;
		const a = ((deg - 90) * Math.PI) / 180;
		out += star(256 + 231 * Math.cos(a), 256 + 231 * Math.sin(a), 24, "#fff3a0");
	}
	return out;
}

function ribbon(label, t, thai) {
	const size = thai ? 46 : label.length >= 4 ? 58 : 66;
	const family = thai ? "'Leelawadee UI','Leelawadee',sans-serif" : FONT;
	return `<g>
		<path d="M150,384 L84,384 L104,412 L84,440 L150,440Z" fill="${t.dark}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<path d="M362,384 L428,384 L408,412 L428,440 L362,440Z" fill="${t.dark}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<rect x="122" y="372" width="268" height="76" rx="20" fill="${t.ribbon}" stroke="${INK}" stroke-width="8"/>
		<rect x="134" y="381" width="244" height="16" rx="8" fill="#ffffff44"/>
		<text x="256" y="${thai ? 427 : 434}" text-anchor="middle" font-family="${family}" font-size="${size}" font-weight="900"
			fill="#fff" stroke="${INK}" stroke-width="11" stroke-linejoin="round" paint-order="stroke">${label}</text>
	</g>`;
}

function badgeSvg(b) {
	const t = TIERS[b.tier];
	return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
	<defs>
		<linearGradient id="rim" x1="0" y1="0" x2="1" y2="1">
			<stop offset="0" stop-color="${t.light}"/><stop offset=".3" stop-color="${t.mid}"/>
			<stop offset=".55" stop-color="${t.light}"/><stop offset=".8" stop-color="${t.mid}"/>
			<stop offset="1" stop-color="${t.dark}"/>
		</linearGradient>
		<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fdcff"/><stop offset="1" stop-color="#e6fbff"/></linearGradient>
		<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fe3f5"/><stop offset="1" stop-color="#1f8fd6"/></linearGradient>
		<linearGradient id="leaf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a9ec6c"/><stop offset="1" stop-color="#55bf4a"/></linearGradient>
		<clipPath id="disc"><circle cx="256" cy="256" r="206"/></clipPath>
		<filter id="sticker" x="-20%" y="-20%" width="140%" height="140%">
			<feMorphology in="SourceAlpha" operator="dilate" radius="7" result="fat"/>
			<feFlood flood-color="#ffffff"/><feComposite in2="fat" operator="in" result="edge"/>
			<feOffset in="fat" dy="7" result="low"/><feFlood flood-color="#00000055"/><feComposite in2="low" operator="in" result="shadow"/>
			<feMerge><feMergeNode in="shadow"/><feMergeNode in="edge"/><feMergeNode in="SourceGraphic"/></feMerge>
		</filter>
	</defs>
	<rect width="512" height="512" fill="${t.mid}"/>
	<circle cx="256" cy="256" r="256" fill="url(#rim)"/>
	${studs()}
	<circle cx="256" cy="256" r="212" fill="${t.dark}" stroke="${INK}" stroke-width="6"/>
	${b.art ? artImage(b) : background(b.cat)}
	<circle cx="256" cy="256" r="206" fill="none" stroke="#ffffff66" stroke-width="5"/>
	${!b.art && BEHIND[b.icon] ? BEHIND[b.icon]() : ""}
	${b.art ? "" : `<g filter="url(#sticker)">${ICONS[b.icon]()}</g>`}
	${!b.art && EXTRAS[b.icon] ? EXTRAS[b.icon]() : ""}
	${rankStars(b.tier)}
	${ribbon(b.label, t, b.thai)}
</svg>`;
}

// ---------- รายการตรา ----------
const BADGES = [
	{ file: "plant_1_10", cat: "plant", tier: 1, label: "10", icon: "plant1" },
	{ file: "plant_2_100", cat: "plant", tier: 2, label: "100", icon: "plant2" },
	{ file: "plant_3_1K", cat: "plant", tier: 3, label: "1,000", icon: "plant3" },
	{ file: "fish_1_10", cat: "fish", tier: 1, label: "10", icon: "fish1" },
	{ file: "fish_2_100", cat: "fish", tier: 2, label: "100", icon: "fish2" },
	{ file: "welcome", cat: "plant", tier: "welcome", label: "ยินดีต้อนรับ", icon: "welcome", thai: true, art: "welcome_art.webp", artX: 36, artY: 34, artSize: 440 },
];

function shot(htmlPath, pngPath, w, h) {
	execFileSync(CHROME, [
		"--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
		`--window-size=${w},${h}`, `--screenshot=${pngPath}`, "file:///" + htmlPath.replace(/\\/g, "/"),
	], { stdio: "ignore" });
}

for (const dir of ["svg", "png"]) fs.mkdirSync(path.join(OUT, dir), { recursive: true });
const tmp = path.join(OUT, "_render.html");
for (const b of BADGES) {
	const svg = badgeSvg(b);
	fs.writeFileSync(path.join(OUT, "svg", b.file + ".svg"), svg);
	fs.writeFileSync(tmp, `<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;overflow:hidden">${svg}</body></html>`);
	shot(tmp, path.join(OUT, "png", b.file + ".png"), 512, 512);
}

// แผ่นตัวอย่าง: แถวบน = ตัดวงกลมแบบ Roblox, แถวล่าง = ขนาดเล็กบนหน้าเกม
const big = BADGES.map((b) => `<img src="png/${b.file}.png" style="width:300px;height:300px;border-radius:50%">`).join("");
const small = BADGES.map((b) => `<img src="png/${b.file}.png" style="width:100px;height:100px;border-radius:50%">`).join("");
fs.writeFileSync(tmp, `<!doctype html><html><body style="margin:0;padding:28px;background:#e3e5e8;overflow:hidden">
	<div style="display:flex;gap:24px">${big}</div>
	<div style="display:flex;gap:24px;margin-top:28px">${small}</div></body></html>`);
shot(tmp, path.join(OUT, "preview.png"), 1996, 540);
fs.unlinkSync(tmp);
console.log("done", BADGES.length);
