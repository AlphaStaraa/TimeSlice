package studio.shiren.mobile;

import android.content.Context;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

/** Library grouping only. Rendering and saved settings retain their original effect IDs. */
public final class EffectGroup {
    public String key, name;
    public int family, defaultId;
    public final List<Variant> variants = new ArrayList<>();

    public static final class Variant {
        public int effect;
        public String motion, orientation;
    }

    /* 判断当前集合是否包含指定效果或组合。 */ public boolean contains(int id) {
        for (Variant variant : variants) if (variant.effect == id) return true;
        return false;
    }

    /* 在形状组内查找指定运动和排列的原始效果。 */ public Variant variant(int id) {
        for (Variant variant : variants) if (variant.effect == id) return variant;
        throw new IllegalArgumentException("Unknown effect in " + key);
    }

    /* 汇总当前形状支持的运动方式。 */ public List<String> motions() {
        LinkedHashSet<String> values = new LinkedHashSet<>();
        for (Variant variant : variants) values.add(variant.motion);
        return new ArrayList<>(values);
    }

    /* 根据所选流动方式筛选同一形状的变体。 */ public List<Variant> forMotion(String motion) {
        List<Variant> result = new ArrayList<>();
        for (Variant variant : variants) if (variant.motion.equals(motion)) result.add(variant);
        return result;
    }

    /* 读取内置资源、效果定义或素材信息。 */ public static List<EffectGroup> load(Context context, List<Effect> effects) throws Exception {
        List<EffectGroup> result = new ArrayList<>();
        addSingles(result, effects, 0);
        JSONArray entries = new JSONArray(new String(Assets.read(context, "catalogue.json"), "UTF-8"));
        for (int i = 0; i < entries.length(); i++) {
            JSONObject entry = entries.getJSONObject(i);
            EffectGroup group = new EffectGroup();
            group.key = entry.getString("key");
            group.name = entry.getString("name");
            group.defaultId = entry.getInt("default");
            group.family = 1;
            JSONArray variants = entry.getJSONArray("variants");
            for (int j = 0; j < variants.length(); j++) {
                JSONObject item = variants.getJSONObject(j);
                Variant variant = new Variant();
                variant.effect = item.getInt("effect");
                variant.motion = item.getString("motion");
                variant.orientation = item.getString("orientation");
                group.variants.add(variant);
            }
            result.add(group);
        }
        addSingles(result, effects, 3);
        return result;
    }

    /* 把独立效果加入当前分类列表。 */ private static void addSingles(List<EffectGroup> result, List<Effect> effects, int family) {
        for (Effect effect : effects) {
            if (effect.family != family) continue;
            EffectGroup group = new EffectGroup();
            group.key = effect.key;
            group.name = effect.name;
            group.defaultId = effect.id;
            group.family = family;
            Variant variant = new Variant();
            variant.effect = effect.id;
            variant.motion = "";
            variant.orientation = "";
            group.variants.add(variant);
            result.add(group);
        }
    }
}
